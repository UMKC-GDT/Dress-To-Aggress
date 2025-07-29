extends Resource

class_name OutfitSaveResource

@export var shirt: String
@export var pants: String

func get_shirt_text() -> String:
	return shirt
	
func get_pants_text() -> String:
	return pants

func set_shirt_text(shirt_name: String) -> void:
	shirt = shirt_name
	
func set_pants_text(pants_name: String) -> void:
	pants= pants_name

	
