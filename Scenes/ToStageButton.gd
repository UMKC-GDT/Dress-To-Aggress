extends Button

@export var InstructionsBoard: Sprite2D

func _ready() -> void:
	# Just in case
	if (InstructionsBoard.visible):
		visible = false;
	else:
		visible = true;

func _on_button_button_down():
	visible = true;
