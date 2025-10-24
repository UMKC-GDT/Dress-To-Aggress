extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7007
const DEFAULT_SERVER_IP = "192.168.0.100" # use your LAN IP for clients
const MAX_CONNECTIONS = 20

var players = {}
var player_info = {"name": "Name"}
var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	
	remove_multiplayer_peer() # clear any existing peer

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Failed to create client:", error)
		return error

	multiplayer.multiplayer_peer = peer
	print("Client attempting to connect to", address, "on port", PORT)


func create_game():
	remove_multiplayer_peer() # clear any existing peer

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != OK:
		print("Failed to create server:", error)
		return error

	multiplayer.multiplayer_peer = peer

	# Add local player (server) info
	var my_id = multiplayer.get_unique_id()
	players[my_id] = player_info
	player_connected.emit(my_id, player_info)
	print("Server created on port", PORT)
	
func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()

# RPCs and player events remain the same
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0

func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	remove_multiplayer_peer()
	print("Connection failed")

func _on_server_disconnected():
	remove_multiplayer_peer()
	server_disconnected.emit()

func _on_username_submitted(new_text: String) -> void:
	player_info["name"] = new_text
	print("Submitted name")
