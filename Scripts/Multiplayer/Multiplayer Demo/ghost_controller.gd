extends Node

@export var nim_path: NodePath = NodePath("../NetworkInputManager")
@export var ghost_scene: PackedScene
@onready var nim: Node = get_node_or_null(nim_path)

var _ghosts: Dictionary = {} # pid -> Node

func _ready() -> void:
	if nim == null:
		push_error("GhostRegistry: missing NIM")
		return
	nim.server_move.connect(_touch_pid_from_move)
	nim.server_action.connect(_touch_pid_from_action)

func _touch_pid_from_move(_tick:int, pid:int, _dx:int, _dy:int) -> void:
	_spawn_if_needed(pid)

func _touch_pid_from_action(_tick:int, pid:int, _a:String) -> void:
	_spawn_if_needed(pid)

func _spawn_if_needed(pid:int) -> void:
	if _ghosts.has(pid): return
	if ghost_scene == null:
		push_error("GhostRegistry: ghost_scene not set"); return
	var inst := ghost_scene.instantiate()
	add_child(inst)
	(inst as Node).set("pid", pid)
	if inst.has_method("bind_to_manager"):
		inst.call("bind_to_manager", nim)
	_ghosts[pid] = inst

func despawn(pid:int) -> void:
	if not _ghosts.has(pid): return
	var n: Node = _ghosts[pid]
	_ghosts.erase(pid)
	if n: n.queue_free()
