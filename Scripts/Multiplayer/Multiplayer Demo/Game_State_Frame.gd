# res://scripts/game_state_frame.gd
class_name GameStateFrame        # this registers it globally
extends RefCounted

var time_stamp: float = 0.0
var local_player_input: Vector2i = Vector2i.ZERO
var online_player_input: Vector2i = Vector2i.ZERO

func _init():
	time_stamp = Time.get_unix_time_from_system()
