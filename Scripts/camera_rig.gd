extends Node2D

# References to the two players
@export var player1: Node2D
@export var player2: Node2D

# The minimum and maximum y-coordinates for the camera
@export var min_y: float = 21
@export var max_y: float = 88

# Smoothing speed for camera movement
@export var smoothing: float = 0.1

func _process(_delta: float) -> void:
    if not player1 or not player2:
        return

    # 1. Calculate the center point between the two players.
    var center_point = (player1.global_position + player2.global_position) / 2.0

    # 2. Get the current position of the camera rig.
    var current_position = global_position

    # 3. Interpolate the camera rig's position to the new center point for smooth movement.
    var new_position = current_position.lerp(center_point, smoothing)

    # 4. Clamp the camera's y-position to the desired limits.
    new_position.y = clamp(new_position.y, min_y, max_y)

    # 5. Update the camera rig's position.
    global_position = new_position
