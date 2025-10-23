extends OptionButton


func _on_item_selected(index: int) -> void:
		match index:
			1:
				global.difficulty = "Easy"
			2:
				global.difficulty = "Normal"
			3:
				global.difficulty = "Hard"
