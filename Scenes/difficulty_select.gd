extends OptionButton

func _ready():
	if global.arcade_level != 0:
		visible = false

func _on_item_selected(index: int) -> void:
		match index:
			1:
				global.difficulty = "Easy"
			2:
				global.difficulty = "Normal"
			3:
				global.difficulty = "Hard"
