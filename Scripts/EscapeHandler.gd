extends Node

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"): # default Escape key
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
