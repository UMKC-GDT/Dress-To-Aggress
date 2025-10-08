extends Node


var is_dragging = false

func roundFloat(flt, place):
	return (round(flt*pow(10,place))/pow(10,place))
