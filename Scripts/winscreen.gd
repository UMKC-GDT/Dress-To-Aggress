extends Node2D

@onready var soundEffect: AudioStreamPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	soundEffect.play()
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
