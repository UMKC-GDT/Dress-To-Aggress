# res://scripts/game_state_frame.gd
class_name GameStateFrame        # this registers it globally
extends RefCounted

var time_stamp: float = 0.0
var client_input: Dictionary = {}
var host_input: Dictionary = {}

func _init():
	time_stamp = Time.get_unix_time_from_system()
