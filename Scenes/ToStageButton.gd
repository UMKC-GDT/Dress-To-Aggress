extends Button


func _ready() -> void:
	# Just in case
	visible = false;

func _on_button_button_down():
	visible = true;
