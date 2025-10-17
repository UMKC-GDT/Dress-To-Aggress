extends Node
# Merge-only “Input Bus”: collects per-tick inputs from all peers,
# builds an authoritative merged input per tick on the HOST, and
# broadcasts it to everyone. No gameplay sim here.

signal server_tick_inputs(tick: int, inputs: Dictionary) # { pid -> {x,y,player_punch} }
# Optional if you want to observe connection state from outside:
signal net_ready()
signal net_down()

@onready var Lobby := get_node_or_null("/root/Lobby")

# --- timing ---
const TICK := 1.0 / 60.0
const SERVER_INPUT_DELAY := 4     # host lags a few ticks to absorb jitter

var accumulator: float = 0.0
var tick_i: int = 0

# --- input history (frames) + last-known input model ---
var frames: Dictionary = {}       # tick -> GameStateFrame (inputs only)
var last_input: Dictionary = {}   # pid -> {x,y,player_punch}
var server_last_received_tick: int = -1

func _ready() -> void:
	print("GSM (InputBus) ready | server=", multiplayer.is_server(), " | id=", multiplayer.get_unique_id())
	set_process(false)
	# Wake when networking is actually live
	multiplayer.connected_to_server.connect(_on_net_ready)
	multiplayer.peer_connected.connect(_on_net_ready)
	multiplayer.server_disconnected.connect(_on_net_down)
	multiplayer.connection_failed.connect(_on_net_down)
	if multiplayer.is_server():
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
	# ticks advance locally so InputCollector can tag inputs with current tick
	tick_i += 1
	_prune_old_frames()

# --- Public API: called by InputCollector on every peer each frame ---
func submit_input_for_current_tick(inp: Dictionary) -> void:
	var t: int = tick_i
	var me: int = multiplayer.get_unique_id()
	var f := _get_or_make_frame(t)
	var clean := {
		"x": int(inp.get("x", 0)),
		"y": int(inp.get("y", 0)),
		"player_punch": bool(inp.get("player_punch", false))
	}
	f.client_input[me] = clean
	last_input[me] = clean
	server_last_received_tick = max(server_last_received_tick, t)
	# Forward to host if we are a client
	if not multiplayer.is_server():
		rpc_id(1, "rpc_client_input", t, clean)

# --- RPC: client -> server (inputs) ---
@rpc("any_peer", "unreliable")
func rpc_client_input(t: int, inp: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var pid := multiplayer.get_remote_sender_id()
	var f := _get_or_make_frame(t)
	var clean := {
		"x": int(inp.get("x", 0)),
		"y": int(inp.get("y", 0)),
		"player_punch": bool(inp.get("player_punch", false))
	}
	f.client_input[pid] = clean
	last_input[pid] = clean
	server_last_received_tick = max(server_last_received_tick, t)
	# print("SRV got input t=", t, " pid=", pid, " inp=", clean)

# --- RPC: server -> all (authoritative merged inputs per tick) ---
@rpc("call_local", "unreliable")
func rpc_inputs_for_tick(t: int, merged: Dictionary) -> void:
	# Store merged as host_input for record/rollback tooling if desired
	var f := _get_or_make_frame(t)
	f.host_input = merged.duplicate(true)
	emit_signal("server_tick_inputs", t, f.host_input)

# --- Host loop: build merged per tick from latest-known inputs ---
func _server_maybe_advance() -> void:
	var target: int = server_last_received_tick - SERVER_INPUT_DELAY
	if target < 0:
		return

	# last published tick is the highest tick with host_input present
	var last_published: int = -1
	for k in frames.keys():
		if frames[k].host_input.size() > 0:
			if k > last_published:
				last_published = k

	for t in range(last_published + 1, target + 1):
		var merged := {}
		var required := _required_pids()
		# Optionally: before first advance, ensure we’ve seen at least one input per pid
		if not _have_seed_for_all(required):
			break
		for pid in required:
			merged[pid] = last_input.get(pid, {"x": 0, "y": 0, "player_punch": false})

		# Publish once. Do NOT also emit locally elsewhere (prevents double-tick on host).
		rpc("rpc_inputs_for_tick", t, merged)

# --- Helpers ---
func _get_or_make_frame(t: int) -> GameStateFrame:
	if not frames.has(t):
		frames[t] = GameStateFrame.new()
	return frames[t]

func _required_pids() -> Array:
	var ids: Array = []
	if Lobby != null:
		var lp: Dictionary = Lobby.get("players") as Dictionary
		if typeof(lp) == TYPE_DICTIONARY:
			for pid in (lp as Dictionary).keys():
				if not ids.has(pid):
					ids.append(pid)
	# always include self; include server(1) for clarity
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
	# Initialize with zeros so host can advance immediately if desired
	for pid in _required_pids():
		if not last_input.has(pid):
			last_input[pid] = {"x": 0, "y": 0, "player_punch": false}

func _prune_old_frames() -> void:
	# Keep only a small window (optional; adjust as needed)
	var cutoff := tick_i - 300 # ~5s at 60Hz
	var to_erase: Array = []
	for k in frames.keys():
		if int(k) < cutoff:
			to_erase.append(k)
	for k in to_erase:
		frames.erase(k)
