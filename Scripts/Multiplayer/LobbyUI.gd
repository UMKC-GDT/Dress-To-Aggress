extends Control

func _on_ButtonHost_pressed():
	Lobby.create_game()

func _on_ButtonJoin_pressed():
	Lobby.join_game("127.0.0.1")

func _on_start_pressed():
	if multiplayer.has_multiplayer_peer():
		global.IsMultiplayer = true
		Lobby.load_game.rpc("res://Scenes/multiStageFight.tscn")
