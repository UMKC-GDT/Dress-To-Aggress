extends Node2D

@onready var codec: Node2D = $Codec

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.arcade_level = -1
	print("Set global arcade level!")
	codec.setup_codec()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
