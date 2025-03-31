extends Control


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/textbox.tscn")


func _on_settings_pressed() -> void:
	print("Settings pressed")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
