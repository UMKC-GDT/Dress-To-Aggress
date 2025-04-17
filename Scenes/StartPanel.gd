extends Sprite2D
 


func _on_button_button_down() -> void:
	self.visible = false
	$"../Dressup Timer".get_child(0).start(10.0)
