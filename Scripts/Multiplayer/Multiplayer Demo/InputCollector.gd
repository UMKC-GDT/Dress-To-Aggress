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

	var inp := {
		"x": int(Input.is_action_pressed("player_right")) - int(Input.is_action_pressed("player_left")),
		"player_left": Input.is_action_pressed("player_left"),
		"player_right": Input.is_action_pressed("player_right"),
		"player_punch": Input.is_action_pressed("player_punch"),
		"player_kick": Input.is_action_pressed("player_kick"),
		"player_jump": Input.is_action_pressed("player_jump"),
		"player_throw": Input.is_action_pressed("player_throw"),
		"player_crouch": Input.is_action_pressed("player_crouch")
	}

	if gsm.has_method("submit_input_for_current_tick"):
		gsm.submit_input_for_current_tick(inp)
