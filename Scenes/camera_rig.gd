extends Node2D

@export var player1: Node2D
@export var player2: Node2D

@export var min_y: float = 21
@export var max_y: float = 88
@export var smoothing: float = 0.1

var ready_to_track := false

func _ready() -> void:
	# Wait a frame to allow other nodes (players) to initialize
	await get_tree().process_frame
	# Check if players were assigned or try to find them dynamically
	if not player1:
		player1 = get_node_or_null("../Player1")
	if not player2:
		player2 = get_node_or_null("../Player2")

	# Enable tracking only if both exist
	if player1 and player2:
		ready_to_track = true

func _process(_delta: float) -> void:
	# Try to find players if not set yet
	if not player1:
		player1 = get_node_or_null("../Player1")
		if not player2:
			return  # wait until both exist
	if not player2:
		player2 = get_node_or_null("../Player2")
		if not player1:
			return  # wait until both exist
		
	# Once found, track
	var center_point = (player1.global_position + player2.global_position) / 2.0
	var current_position = global_position
	var new_position = current_position.lerp(center_point, smoothing)
	new_position.y = clamp(new_position.y, min_y, max_y)
	global_position = new_position
