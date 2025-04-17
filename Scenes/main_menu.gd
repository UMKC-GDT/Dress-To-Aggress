extends Control


func _on_start_pressed() -> void:
	SfxManager.playClick()
	get_tree().change_scene_to_file("res://Scenes/textbox.tscn")


func _on_settings_pressed() -> void:
	SfxManager.playClick()
	print("Settings pressed")


func _on_exit_pressed() -> void:
	SfxManager.playClick()
	get_tree().quit()


func _on_credits_pressed() -> void:
	SfxManager.playClick()
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
