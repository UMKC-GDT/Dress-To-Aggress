extends Node2D


func _process(delta: float) -> void:
	$RichTextLabel.position.y -= 50 * delta


func _on_timer_timeout() -> void:
	$Button.visible = true


func _on_button_pressed() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/main_menu.tscn")
