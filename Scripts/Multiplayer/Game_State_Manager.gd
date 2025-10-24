extends Node
# Merge-only “Input Bus”: schema-agnostic.
# Collects per-tick inputs from all peers, merges on HOST, and broadcasts.

signal server_tick_inputs(tick: int, inputs: Dictionary) # { pid -> {k -> v} }
signal server_set_ownership(p1: int, p2: int)
signal net_ready()
signal net_down()

@onready var Lobby := get_node_or_null("/root/Lobby")
@onready var player1: CharacterBody2D = $"../Player"
@onready var player2: CharacterBody2D = $"../Player1"

const TICK := 1.0 / 60.0
const SERVER_INPUT_DELAY := 8

var accumulator: float = 0.0
var tick_i: int = 0

var frames: Dictionary = {}         # tick -> GameStateFrame (inputs only)
var last_input: Dictionary = {}     # pid -> Dictionary
var server_last_received_tick: int = -1

# Tracks the union of keys we've seen and their coerced "kind"
# kind: "bool" | "int"  (floats are rounded to int; others ignored)
var key_kinds: Dictionary = {}      # key -> String

func _ready() -> void:
	print("GSM (InputBus) ready | server=", multiplayer.is_server(), " | id=", multiplayer.get_unique_id())
	set_process(false)
	multiplayer.connected_to_server.connect(_on_net_ready)
	multiplayer.peer_connected.connect(_on_net_ready)
	multiplayer.server_disconnected.connect(_on_net_down)
	multiplayer.connection_failed.connect(_on_net_down)
	
	if multiplayer.is_server(): 
		#print("Multiplayer: " + str(multiplayer.multiplayer_peer.get_unique_id()))
		rpc("rpc_set_ownership",multiplayer.get_unique_id(), multiplayer.multiplayer_peer.get_unique_id())
		_on_net_ready(1)

func _on_net_ready(_id := 0) -> void:
	_seed_last_inputs()
	if not is_processing():
		set_process(true)
	emit_signal("net_ready")

func _on_net_down() -> void:
	set_process(false)
	emit_signal("net_down")

func _process(delta: float) -> void:
	accumulator += delta
	while accumulator >= TICK:
		_tick_once()
		if multiplayer.is_server():
			_server_maybe_advance()
		accumulator -= TICK

func _tick_once() -> void:
	tick_i += 1
	_prune_old_frames()

# ---- Public API ----
func submit_input_for_current_tick(inp: Dictionary) -> void:
	var t: int = tick_i
	var me: int = multiplayer.get_unique_id()
	var f := _get_or_make_frame(t)

	var clean := _clean_and_record(inp)
	f.client_input[me] = clean
	last_input[me] = clean
	server_last_received_tick = max(server_last_received_tick, t)

	if not multiplayer.is_server():
		rpc_id(1, "rpc_client_input", t, clean)

# ---- RPC: client -> server ----
@rpc("any_peer", "unreliable")
func rpc_client_input(t: int, inp: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var pid := multiplayer.get_remote_sender_id()
	var f := _get_or_make_frame(t)

	var clean := _clean_and_record(inp)
	f.client_input[pid] = clean
	last_input[pid] = clean
	server_last_received_tick = max(server_last_received_tick, t)

# ---- RPC: server -> all ----
@rpc("call_local", "unreliable")
func rpc_set_ownership(p1: int, p2: int) -> void:
	player2.pid = p2
	player1.pid = p1

@rpc("call_local", "unreliable")
func rpc_inputs_for_tick(t: int, merged: Dictionary) -> void:
	var f := _get_or_make_frame(t)
	f.host_input = merged.duplicate(true)
	emit_signal("server_tick_inputs", t, f.host_input)

# ---- Host loop ----
func _server_maybe_advance() -> void:
	var target: int = server_last_received_tick - SERVER_INPUT_DELAY
	if target < 0:
		return

	var last_published: int = -1
	for k in frames.keys():
		if frames[k].host_input.size() > 0 and k > last_published:
			last_published = k

	for t in range(last_published + 1, target + 1):
		var merged := {}
		var required := _required_pids()
		if not _have_seed_for_all(required):
			break

		# Build a complete record per pid with defaults for any missing keys
		for pid in required:
			var src: Dictionary = last_input.get(pid, {})
			merged[pid] = _fill_defaults(src)

		rpc("rpc_inputs_for_tick", t, merged)

# ---- Helpers ----
func _get_or_make_frame(t: int) -> GameStateFrame:
	if not frames.has(t):
		frames[t] = GameStateFrame.new()
	return frames[t]

func _required_pids() -> Array:
	var ids: Array = []
	if Lobby != null:
		var lp: Dictionary = Lobby.get("players") as Dictionary
		if typeof(lp) == TYPE_DICTIONARY:
			for pid in lp.keys():
				if not ids.has(pid):
					ids.append(pid)
	var me := multiplayer.get_unique_id()
	if not ids.has(me):
		ids.append(me)
	if multiplayer.is_server() and not ids.has(1):
		ids.append(1)
	return ids

func _have_seed_for_all(required: Array) -> bool:
	for pid in required:
		if not last_input.has(pid):
			return false
	return true

func _seed_last_inputs() -> void:
	for pid in _required_pids():
		if not last_input.has(pid):
			last_input[pid] = {}

func _prune_old_frames() -> void:
	var cutoff := tick_i - 300
	var to_erase: Array = []
	for k in frames.keys():
		if int(k) < cutoff:
			to_erase.append(k)
	for k in to_erase:
		frames.erase(k)

# ---- Schema-agnostic sanitation & defaults ----
func _clean_and_record(inp: Dictionary) -> Dictionary:
	var out := {}
	for k in inp.keys():
		var v = inp[k]
		match typeof(v):
			TYPE_BOOL:
				out[k] = bool(v)
				# once a key is bool, keep it bool
				if not key_kinds.has(k):
					key_kinds[k] = "bool"
			TYPE_INT:
				out[k] = int(v)
				if not key_kinds.has(k):
					key_kinds[k] = "int"
			TYPE_FLOAT:
				# determinism: quantize to int
				out[k] = int(round(v))
				if not key_kinds.has(k):
					key_kinds[k] = "int"
			# Optional: allow Vector2/Vector2i by projecting to ints
			TYPE_VECTOR2, TYPE_VECTOR2I:
				var vi: Vector2i = Vector2i(v)
				out["%s_x" % k] = int(vi.x)
				out["%s_y" % k] = int(vi.y)
				# record the projected keys as ints
				if not key_kinds.has("%s_x" % k):
					key_kinds["%s_x" % k] = "int"
				if not key_kinds.has("%s_y" % k):
					key_kinds["%s_y" % k] = "int"
			_:
				# ignore unsupported types to keep net messages tight & deterministic
				pass
	return out

func _fill_defaults(src: Dictionary) -> Dictionary:
	# Ensure every known key is present with a default based on kind
	var dst := src.duplicate()
	for k in key_kinds.keys():
		if not dst.has(k):
			dst[k] = (false if key_kinds[k] == "bool" else 0)
	return dst
