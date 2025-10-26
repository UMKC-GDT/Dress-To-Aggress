extends Node2D

@onready var soundEffect: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var soundEffect2: AudioStreamPlayer2D = $AudioStreamPlayer2D2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	soundEffect2.play()
	await get_tree().create_timer(1.0).timeout
	soundEffect.play()
	
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
