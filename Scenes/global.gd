extends Node


var is_dragging = false

var difficulty = "Normal"
var arcade_level = 0
var instructions_board_seen = false

var dialogueScene: String = "res://Assets/Resources/Dialogues/TestDialogue.tres"

func roundFloat(flt, place):
	return (round(flt*pow(10,place))/pow(10,place))
