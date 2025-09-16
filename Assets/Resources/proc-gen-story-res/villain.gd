extends Resource
class_name Villain

@export var codename: String
@export var epithet: String = ""
@export var style_tags: Array[String] = []
@export var m_o: String = ""
@export_range(1, 10, 1) var threat_level: int = 5
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

func display_label() -> String:
	return (codename + " the " + epithet)
