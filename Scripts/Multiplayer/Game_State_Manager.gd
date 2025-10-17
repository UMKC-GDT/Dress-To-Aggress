extends Node

@onready var Lobby := get_node_or_null("/root/Lobby")

# ---------- Debug ----------
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
const RESYNC_EVERY := 60 * 5          # full state every 5s
const SERVER_INPUT_DELAY := 2         # host waits behind latest received

var accumulator: float = 0.0
var tick_i: int = 0

# ---------- Sim ----------
var players_pos: Dictionary = {}      # peer_id -> Vector2i
const SPEED_PER_TICK: int = 6

# ---------- History ----------
var state_buffer: Dictionary = {}     # tick -> PackedByteArray (snapshots)
var frames: Dictionary = {}           # tick -> GameStateFrame

# ---------- Net ----------
var last_confirmed_tick := -1
var server_last_received_tick := -1

func _ready() -> void:
	if multiplayer.get_peers().size() == 0:
		print("No peers, turning off multiplayer")
		self.set_process(false)
		return
	print("GSM ready | server=", multiplayer.is_server(), " | id=", multiplayer.get_unique_id())
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

# ---------- Core tick ----------
func _tick_once() -> void:
	var my_move := Vector2i(
		int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	)

	var f := _get_or_make_frame(tick_i)
	var me := multiplayer.get_unique_id()
	f.client_input[me] = my_move

	_send_input(tick_i, my_move)

	if not multiplayer.is_server():
		var merged: Dictionary
		if frames.has(tick_i) and frames[tick_i].host_input.size() > 0:
			merged = frames[tick_i].host_input
		else:
			merged = _merged_inputs_for_tick_local(tick_i, my_move)
		_step_sim_with_inputs(merged)
		state_buffer[tick_i] = _serialize_state()

	tick_i += 1
	_prune_buffers()

# ---------- RPC: client → server (inputs) ----------
@rpc("any_peer", "unreliable")
func rpc_client_input(t: int, move: Vector2i) -> void:
	if multiplayer.is_server():
		var pid := multiplayer.get_remote_sender_id()
		var f := _get_or_make_frame(t)
		f.client_input[pid] = move
		server_last_received_tick = max(server_last_received_tick, t)
		dbg_cli_inputs_recv += 1
		dbg_last_inputs_tick = t
		if t % 10 == 0:
			print("SRV got input t=", t, " pid=", pid, " move=", move)

# ---------- RPC: server → all (merged inputs per tick) ----------
@rpc("call_local", "unreliable")
func rpc_inputs_for_tick(t: int, merged: Dictionary) -> void:
	var f := _get_or_make_frame(t)
	f.host_input = merged.duplicate(true)

	if multiplayer.is_server():
		return
	if t >= tick_i:
		return

	var base_tick: int = max(t - 1, 0)
	var base_snap: PackedByteArray = state_buffer.get(base_tick, null)
	if base_snap == null:
		base_tick = 0
		base_snap = state_buffer.get(0, null)
	if base_snap == null:
		return

	_deserialize_state(base_snap)

	for k in range(base_tick + 1, tick_i):
		var mk := _my_move_for_tick(k)
		var merged_k: Dictionary
		if frames.has(k) and frames[k].host_input.size() > 0:
			merged_k = frames[k].host_input
		else:
			merged_k = _merged_inputs_for_tick_local(k, mk)
		_step_sim_with_inputs(merged_k)
		state_buffer[k] = _serialize_state()

# ---------- RPC: server → all (state correction) ----------
@rpc("call_local", "unreliable")
func rpc_state_correction(t: int, bytes: PackedByteArray, h: int) -> void:
	if not multiplayer.is_server():
		dbg_cli_corr_recv += 1
		dbg_last_corr_tick = t
		print("CLI correction t=", t, " hash=", h)

	var mine_bytes: PackedByteArray = state_buffer.get(t, null)
	if mine_bytes != null and _state_hash(mine_bytes) == h:
		last_confirmed_tick = max(last_confirmed_tick, t)
		_prune_buffers()
		return

	_deserialize_state(bytes)

	for k in range(t + 1, tick_i):
		var mk := _my_move_for_tick(k)
		var merged: Dictionary
		if frames.has(k) and frames[k].host_input.size() > 0:
			merged = frames[k].host_input
		else:
			merged = _merged_inputs_for_tick_local(k, mk)
		_step_sim_with_inputs(merged)
		state_buffer[k] = _serialize_state()

	last_confirmed_tick = max(last_confirmed_tick, t)
	_prune_buffers()

# ---------- Server authoritative advance ----------
func _server_maybe_advance() -> void:
	var target: int = server_last_received_tick - SERVER_INPUT_DELAY
	if target < 0:
		return

	var last_server_tick: int = -1
	for k in state_buffer.keys():
		last_server_tick = max(last_server_tick, k)

	for t in range(last_server_tick + 1, target + 1):
		var merged := _merged_inputs_for_tick_server(t)

		var f := _get_or_make_frame(t)
		f.host_input = merged.duplicate(true)

		_step_sim_with_inputs(merged)
		var snap := _serialize_state()
		state_buffer[t] = snap

		dbg_srv_steps += 1
		if (t % 15) == 0:
			print("SRV step t=", t, " merged=", merged, " pos=", players_pos)

		rpc("rpc_inputs_for_tick", t, merged)
		if (t % RESYNC_EVERY) == 0:
			rpc("rpc_state_correction", t, snap, _state_hash(snap))

# ---------- Helpers ----------
func _get_or_make_frame(t: int) -> GameStateFrame:
	if not frames.has(t):
		frames[t] = GameStateFrame.new()
	return frames[t]

func _my_move_for_tick(t: int) -> Vector2i:
	var me := multiplayer.get_unique_id()
	if frames.has(t) and frames[t].client_input.has(me):
		return frames[t].client_input[me]
	return Vector2i.ZERO

func _merged_inputs_for_tick_server(t: int) -> Dictionary:
	var merged := {}
	for pid in _player_ids_for_tick(t):
		var mv := Vector2i.ZERO
		if frames.has(t) and frames[t].client_input.has(pid):
			mv = frames[t].client_input[pid]
		merged[pid] = mv
	return merged

func _merged_inputs_for_tick_local(t: int, my_move: Vector2i) -> Dictionary:
	var me := multiplayer.get_unique_id()
	var merged: Dictionary = {}
	if frames.has(t) and frames[t].host_input.size() > 0:
		merged = frames[t].host_input.duplicate(true)
	if not merged.has(me):
		merged[me] = my_move
	for pid in _player_ids_for_tick(t):
		if not merged.has(pid):
			merged[pid] = Vector2i.ZERO
	return merged

func _all_player_ids() -> Array:
	if Lobby != null:
		var lp: Variant = Lobby.get("players")
		if typeof(lp) == TYPE_DICTIONARY:
			return (lp as Dictionary).keys()
	var ids: Array = [multiplayer.get_unique_id()]
	if multiplayer.is_server() and not ids.has(1):
		ids.append(1)
	return ids

func _player_ids_for_tick(t: int) -> Array:
	var ids: Array = []

	for pid in players_pos.keys():
		if not ids.has(pid):
			ids.append(pid)

	if Lobby != null and typeof(Lobby.players) == TYPE_DICTIONARY:
		for pid in (Lobby.players as Dictionary).keys():
			if not ids.has(pid):
				ids.append(pid)

	if frames.has(t):
		for pid in frames[t].client_input.keys():
			if not ids.has(pid):
				ids.append(pid)
		for pid in frames[t].host_input.keys():
			if not ids.has(pid):
				ids.append(pid)

	var me := multiplayer.get_unique_id()
	if not ids.has(me):
		ids.append(me)
	if multiplayer.is_server() and not ids.has(1):
		ids.append(1)

	return ids

# ---------- Transport ----------
func _send_input(t: int, move: Vector2i) -> void:
	if multiplayer.is_server():
		var pid := multiplayer.get_unique_id()
		var f := _get_or_make_frame(t)
		f.client_input[pid] = move
		server_last_received_tick = max(server_last_received_tick, t)
	else:
		rpc_id(1, "rpc_client_input", t, move)

# ---------- Deterministic sim ----------
func _step_sim_with_inputs(merged: Dictionary) -> void:
	for pid in merged.keys():
		if players_pos.get(pid) == null:
			players_pos[pid] = Vector2i.ZERO
		players_pos[pid] += (merged[pid] as Vector2i) * SPEED_PER_TICK

	var pos_copy: Dictionary = {}
	for k in players_pos.keys():
		pos_copy[int(k)] = players_pos[k]
	emit_signal("positions_updated", pos_copy)

# ---------- Serialization ----------
func _serialize_state() -> PackedByteArray:
	var ordered: Dictionary = {}
	var keys: Array = players_pos.keys()
	keys.sort()
	for pid in keys:
		ordered[str(pid)] = players_pos[pid]
	var bytes: PackedByteArray = var_to_bytes(ordered)
	return bytes

func _deserialize_state(bytes: PackedByteArray) -> void:
	var v: Variant = bytes_to_var(bytes)
	var state_dict: Dictionary = v as Dictionary
	players_pos.clear()
	for k in state_dict.keys():
		players_pos[int(k)] = state_dict[k]

func _state_hash(bytes: PackedByteArray) -> int:
	return hash(bytes)

# ---------- Housekeeping ----------
func _prune_buffers() -> void:
	var cutoff := tick_i - MAX_ROLLBACK

	for k in state_buffer.keys():
		if k < cutoff:
			state_buffer.erase(k)

	for k in frames.keys():
		if k < cutoff:
			frames.erase(k)
