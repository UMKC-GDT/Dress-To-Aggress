extends Resource
class_name IllicitActivity

@export var title: String
@export var description: String = ""
@export var tags: Array[String] = []
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

func display_label() -> String:
	return title
