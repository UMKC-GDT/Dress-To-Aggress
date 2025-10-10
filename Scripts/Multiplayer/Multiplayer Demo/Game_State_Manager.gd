extends Node

@onready var Lobby := get_node_or_null("/root/Lobby")

var dbg_srv_steps: int = 0
var dbg_cli_inputs_recv: int = 0
var dbg_cli_corr_recv: int = 0
var dbg_last_inputs_tick: int = -1
var dbg_last_corr_tick: int = -1

# ---------- Signals ----------
signal positions_updated(pos: Dictionary)
 
# ---------- Ticks / windows ----------
const TICK := 1.0 / 60.0
const MAX_ROLLBACK: int = 30          # ~0.5s
const RESYNC_EVERY := 60 * 5      # full state every 5s
const SERVER_INPUT_DELAY := 2     # server waits N ticks behind latest received

var accumulator: float = 0.0
var tick_i: int = 0

# ---------- Sim: positions per player (deterministic ints) ----------
var players_pos: Dictionary = {}  # peer_id -> Vector2i
const SPEED_PER_TICK: int = 6

# ---------- History ----------
var state_buffer: Dictionary = {}     # tick -> PackedByteArray
var input_buffer: Dictionary = {}     # tick -> Dictionary(peer_id->Vector2i)  (server-auth or received)
var my_inputs: Dictionary = {}        # tick -> Vector2i

# ---------- Net ----------
var last_confirmed_tick := -1
var server_last_received_tick := -1

func _ready() -> void:
	if multiplayer.get_peers().size() == 0:
		print("No peers, turning off multiplayer")
		self.set_process(false)
		return
	print("GSM ready | server=", multiplayer.is_server(), " | id=", multiplayer.get_unique_id())
	# simple: start everyone at 0 (or lay out by small index)
	for pid in _all_player_ids():
		players_pos[pid] = Vector2i(80, 80)
	emit_signal("positions_updated", players_pos.duplicate(true))

func _process(delta: float) -> void:
	accumulator += delta
	while accumulator >= TICK:
		_tick_once()
		if multiplayer.is_server():
			_server_maybe_advance()
		accumulator -= TICK

func _tick_once() -> void:
	var my_move := Vector2i(
		int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	)
	my_inputs[tick_i] = my_move
	_send_input(tick_i, my_move)

	if not multiplayer.is_server():
		# Client prediction only
		var merged: Dictionary = _merged_inputs_for_tick_local(tick_i, my_move)
		_step_sim_with_inputs(merged)
		state_buffer[tick_i] = _serialize_state()

	tick_i += 1
	_prune_buffers()

# ---------------- RPC: client → server (inputs) ----------------
@rpc("any_peer", "unreliable")
func rpc_client_input(t: int, move: Vector2i) -> void:
	if multiplayer.is_server():
		var pid := multiplayer.get_remote_sender_id()
		if input_buffer.get(t) == null: input_buffer[t] = {}
		input_buffer[t][pid] = move
		server_last_received_tick = max(server_last_received_tick, t)
		if t % 10 == 0: print("SRV got input t=", t, " pid=", pid, " move=", move)

# ---------------- RPC: server → all (merged inputs per tick) ----------------
@rpc("call_local", "unreliable")
func rpc_inputs_for_tick(t: int, merged: Dictionary) -> void:
	input_buffer[t] = merged
	if multiplayer.is_server(): return
	# replay only up to tick_i - 1 (exclude current in-flight tick)
	if t >= tick_i: return

	# base = last snapshot BEFORE the first tick we need to fix
	var base_tick: int = max(t - 1, 0)
	var base_snap: PackedByteArray = state_buffer.get(base_tick, null)
	if base_snap == null:
		# fallback: start from 0 if we don't have a pre-step snapshot
		base_tick = 0
		base_snap = state_buffer.get(0, null)
	if base_snap == null: return

	_deserialize_state(base_snap)

	for k in range(base_tick + 1, tick_i):  # <- stops at tick_i-1
		var my_move: Vector2i = my_inputs.get(k, Vector2i.ZERO)
		var merged_k: Dictionary
		if input_buffer.has(k):
			merged_k = input_buffer[k]  # authoritative merged (includes server + maybe me)
		else:
			merged_k = _merged_inputs_for_tick_local(k, my_move)  # predict
		_step_sim_with_inputs(merged_k)
		state_buffer[k] = _serialize_state()

# ---------------- RPC: server → all (state correction) ----------------
@rpc("call_local", "unreliable")
func rpc_state_correction(t: int, bytes: PackedByteArray, h: int) -> void:
	if not multiplayer.is_server():
		dbg_cli_corr_recv += 1
		dbg_last_corr_tick = t
		print("CLI correction t=", t, " hash=", h)
	# state_buffer holds PackedByteArray snapshots, not Dictionaries
	var mine_bytes: PackedByteArray = state_buffer.get(t, null)
	if mine_bytes != null and _state_hash(mine_bytes) == h:
		last_confirmed_tick = max(last_confirmed_tick, t)
		_prune_buffers()
		return

	# Desync: apply authoritative snapshot and replay
	_deserialize_state(bytes)

	for k in range(t + 1, tick_i):
		var my_move: Vector2i = my_inputs.get(k, Vector2i.ZERO)
		var merged: Dictionary = _merged_inputs_for_tick_local(k, my_move)
		_step_sim_with_inputs(merged)
		state_buffer[k] = _serialize_state()

	last_confirmed_tick = max(last_confirmed_tick, t)
	_prune_buffers()

# ---------------- Server advance (authoritative) ----------------
func _server_maybe_advance() -> void:
	# how far we can safely step (leave a small delay)
	var target: int = server_last_received_tick - SERVER_INPUT_DELAY
	if target < 0:
		return

	# last tick we advanced on the server
	var last_server_tick: int = -1
	for k in state_buffer.keys():
		last_server_tick = max(last_server_tick, k)

	var start: int = last_server_tick + 1
	for t in range(start, target + 1):
		var merged := _merged_inputs_for_tick_server(t)
		_step_sim_with_inputs(merged)
		var snap := _serialize_state()
		state_buffer[t] = snap

		# --- Debug ---
		dbg_srv_steps += 1
		if (t % 15) == 0:
			print("SRV step t=", t, " merged=", merged, " pos=", players_pos)

		rpc("rpc_inputs_for_tick", t, merged)
		if (t % RESYNC_EVERY) == 0:
			rpc("rpc_state_correction", t, snap, _state_hash(snap))
	
# ---------------- Helpers: build merged inputs ----------------
func _merged_inputs_for_tick_server(t: int) -> Dictionary:
	var merged := {}
	for pid in _player_ids_for_tick(t):
		var mv: Vector2i = input_buffer.get(t, {}).get(pid, Vector2i.ZERO)
		merged[pid] = mv
	return merged

func _merged_inputs_for_tick_local(t: int, my_move: Vector2i) -> Dictionary:
	var merged: Dictionary = input_buffer.get(t, {}).duplicate(true) if input_buffer.has(t) else {}
	var my_id := multiplayer.get_unique_id()
	if not merged.has(my_id):
		merged[my_id] = my_move
	for pid in _player_ids_for_tick(t):
		if not merged.has(pid): merged[pid] = Vector2i.ZERO
	return merged

func _all_player_ids() -> Array:
	if Lobby != null:
		var lp: Dictionary = Lobby.get("players")  # returns null if property missing
		if typeof(lp) == TYPE_DICTIONARY:
			return (lp as Dictionary).keys()
	# fallback if Lobby isn’t present or players missing
	var ids: Array = [multiplayer.get_unique_id()]
	if multiplayer.is_server() and not ids.has(1):
		ids.append(1)
	return ids

func _player_ids_for_tick(t: int) -> Array:
	var ids: Array = []
	for pid in input_buffer.get(t, {}).keys():
		if not ids.has(pid): ids.append(pid)
	for pid in players_pos.keys():
		if not ids.has(pid): ids.append(pid)
	if Lobby != null and typeof(Lobby.players) == TYPE_DICTIONARY:
		for pid in (Lobby.players as Dictionary).keys():
			if not ids.has(pid): ids.append(pid)
	var me := multiplayer.get_unique_id()
	if not ids.has(me): ids.append(me)      # <- ensure self
	if multiplayer.is_server() and not ids.has(1):
		ids.append(1)
	return ids

# ---------------- Transport ----------------
func _send_input(t: int, move: Vector2i) -> void:
	if multiplayer.is_server():
		var pid := multiplayer.get_unique_id()   # usually 1
		if input_buffer.get(t) == null:
			input_buffer[t] = {}
		input_buffer[t][pid] = move
		server_last_received_tick = max(server_last_received_tick, t)
	else:
		rpc_id(1, "rpc_client_input", t, move)

# ---------------- Deterministic sim ----------------
func _step_sim_with_inputs(merged: Dictionary) -> void:
	for pid in merged.keys():
		if players_pos.get(pid) == null:
			players_pos[pid] = Vector2i.ZERO
		players_pos[pid] += (merged[pid] as Vector2i) * SPEED_PER_TICK

	# make a copy with int keys to avoid "2" vs 2 mismatches
	var pos_copy: Dictionary = {}
	for k in players_pos.keys():
		pos_copy[int(k)] = players_pos[k]
	emit_signal("positions_updated", pos_copy)

# ---- serialization ----
func _serialize_state() -> PackedByteArray:
	var ordered: Dictionary = {}
	var keys: Array = players_pos.keys()
	keys.sort()
	for pid in keys:
		ordered[str(pid)] = players_pos[pid]
	var bytes: PackedByteArray = var_to_bytes(ordered)   # <-- Godot 4 global
	return bytes

func _deserialize_state(bytes: PackedByteArray) -> void:
	var v: Variant = bytes_to_var(bytes)                  # <-- Godot 4 global
	var state_dict: Dictionary = v as Dictionary
	players_pos.clear()
	for k in state_dict.keys():
		players_pos[int(k)] = state_dict[k]

func _state_hash(bytes: PackedByteArray) -> int:
	var h: int = hash(bytes)                              # <-- global hash()
	return h

# ---------------- Housekeeping ----------------
func _prune_buffers() -> void:
	var cutoff := tick_i - MAX_ROLLBACK
	for k in input_buffer.keys():
		if k < cutoff: input_buffer.erase(k)
	for k in state_buffer.keys():
		if k < cutoff: state_buffer.erase(k)
	for k in my_inputs.keys():
		if k < cutoff: my_inputs.erase(k)
