extends Resource
class_name FashionHub

@export var name: String
@export var city: String
@export var country: String
@export var description: String = ""
@export var tags: Array[String] = []
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

func display_label() -> String:
	return name if name != "" else "%s, %s" % [city, country]
