extends Node


var is_dragging = false

var difficulty = "Normal"
var arcade_level = 0
var player_level_losses = 0

var currentDialogueScene = 0
var lostLastFight = false

func roundFloat(flt, place):
	return (round(flt*pow(10,place))/pow(10,place))
