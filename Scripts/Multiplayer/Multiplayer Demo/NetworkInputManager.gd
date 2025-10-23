extends Node

signal fighter_registered(pid:int, node:Node)

signal server_move(tick: int, pid: int, dx: int, dy: int)
signal server_action(tick: int, pid: int, action: String)
signal server_rollback(tick: int, pid: int, action: String)

@onready var bar_local  : Node = $"../CanvasLayer/Healthbar"
@onready var bar_remote : Node = $"../CanvasLayer/Healthbar2"

var pid_to_fighter: Dictionary = {}   # pid -> controller node
var pid_to_bar: Dictionary = {}       # pid -> bar node

@export var gsm_path: NodePath = NodePath("..")
@onready var gsm: Node = get_node_or_null(gsm_path)

var _seen_actions_by_tick: Dictionary = {} # tick -> { pid -> {action->bool} }

func _ready() -> void:
	if gsm == null or not gsm.has_signal("server_tick_inputs"):
		push_error("NIM: missing GSM or 'server_tick_inputs'")
		set_process(false)
		return
	gsm.connect("server_tick_inputs", Callable(self, "_on_server_tick_inputs"))

func register_fighter(pid:int, fighter:Node) -> void:
	pid_to_fighter[pid] = fighter
	_assign_bar(pid, fighter)
	fighter_registered.emit(pid, fighter)

func unregister_fighter(pid:int) -> void:
	pid_to_fighter.erase(pid)
	pid_to_bar.erase(pid)

func _assign_bar(pid:int, fighter:Node) -> void:
	if fighter == null: return
	var local_pid := multiplayer.get_unique_id()
	var bar := bar_local if (pid == local_pid) else bar_remote
	pid_to_bar[pid] = bar

	# inject into controller
	if fighter.has_variable("healthbar"):
		fighter.healthbar = bar
	if bar and bar.has_method("init_health") and fighter.has_variable("health"):
		bar.init_health(fighter.health)

# inputs: { "pid_str" -> { "x": int, "y": int, "player_punch": bool, ... } }
func _on_server_tick_inputs(tick: int, inputs: Dictionary) -> void:
	if not _seen_actions_by_tick.has(tick):
		_seen_actions_by_tick[tick] = {}
	var prev: Dictionary = _seen_actions_by_tick[tick]

	for k in inputs.keys():
		var pid := int(k)
		var inp: Dictionary = inputs[k]

		var dx := int(inp.get("x", 0))
		var dy := int(inp.get("y", 0))
		if dx != 0 or dy != 0:
			emit_signal("server_move", tick, pid, dx, dy)

		var now := {
			"punch":  bool(inp.get("player_punch", 0)),
			"kick":   bool(inp.get("player_kick", 0)),
			"jump":   bool(inp.get("player_jump", 0)),
			"throw":  bool(inp.get("player_throw", 0)),
			"crouch": bool(inp.get("player_crouch", 0)),
		}
		var prior: Dictionary = prev.get(pid, {})

		for action in now.keys():
			var cur := bool(now[action])
			var was := bool(prior.get(action, false))
			if cur: emit_signal("server_action", tick, pid, action)
			elif was and not cur: emit_signal("server_rollback", tick, pid, action)

		prev[pid] = now

	_prune_history(tick)

func _prune_history(current_tick: int) -> void:
	var keep_from: int = max(0, current_tick - 180) # ~3s @ 60 Hz
	for t in _seen_actions_by_tick.keys():
		if int(t) < keep_from:
			_seen_actions_by_tick.erase(t)
