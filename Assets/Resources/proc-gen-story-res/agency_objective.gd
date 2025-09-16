extends Resource
class_name AgencyObjective

@export var title: String
@export var description: String = ""
@export var stealthy: bool = false
@export var combat_heavy: bool = true
@export var tags: Array[String] = []
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

func display_label() -> String:
	return title
