extends Node

@onready var Lobby := $Lobby

func _ready() -> void:
	# Ensure the child exists/ready
	if Lobby == null:
		push_error("NetworkController not found"); return

	# Connect signals to parent handlers
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)
	Lobby.player_loaded.rpc_id(1)

# Called only on the server.
func start_game():
	print("Starting game")

func _on_player_connected(peer_id: int, player_info: Dictionary) -> void:
	print("Joined:", peer_id, player_info)

func _on_player_disconnected(peer_id: int) -> void:
	print("Left:", peer_id)

func _on_server_disconnected() -> void:
	print("Server disconnected")
