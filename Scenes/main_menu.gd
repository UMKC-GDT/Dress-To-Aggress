extends Control

@onready
var tutorialControls: Panel = $"How to Play 1"

@onready
var tutorialCombat: Panel = $"How to Play 2"

@onready
var tutorialClothes: Panel = $"How to Play 3"


func _on_start_pressed() -> void:
	global.arcade_level = 0
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

func _on_how_to_button_pressed() -> void:
	tutorialControls.show()

func _on_next_button_pressed() -> void:
	tutorialControls.hide()
	tutorialCombat.show()

func _on_next_button_2_pressed() -> void:
	tutorialCombat.hide()
	tutorialClothes.show()

func _on_got_it_button_pressed() -> void:
	tutorialClothes.hide()
	tutorialCombat.hide()
	tutorialControls.hide()

func _on_arcade_button_button_down() -> void:
	global.arcade_level = 1
	get_tree().change_scene_to_file("res://Scenes/DressUp.tscn")
