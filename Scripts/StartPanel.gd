extends Sprite2D
 


func _on_button_button_down() -> void:
	self.visible = false
	
	# Don't need this anymore, but if we decide to have an option that re-enables the timer, we can reuse this
	#$"../Dressup Timer".get_child(0).start(10.0)
