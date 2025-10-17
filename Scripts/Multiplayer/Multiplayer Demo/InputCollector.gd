extends Node

@export var gsm_path: NodePath = NodePath("..")
@onready var gsm: Node = get_node_or_null(gsm_path)

func _ready() -> void:
	if gsm == null:
		push_error("InputCollector: cannot find GSM at %s" % gsm_path)
		set_process(false)

func _process(_delta: float) -> void:
	if gsm == null:
		return

	var move := Vector2i(
		int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	)

	var inp := {
		"x": move.x,
		"y": move.y,
		"player_punch": Input.is_action_just_pressed("player_punch")
	}

	if gsm.has_method("submit_input_for_current_tick"):
		gsm.submit_input_for_current_tick(inp)
