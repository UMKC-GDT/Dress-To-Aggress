extends Sprite2D

# Change the text based on the arcade level, also maybe based on win/loss
#func _ready():
	#var textbox = $RichTextLabel
	#match global.arcade_level:
		#0: 
			#textbox.text = "Drag and Drop clothing items onto your player.
#
#Create your disguise and press START to begin the match!"
			#textbox.size = Vector2(260.5,137)
			#textbox.position = Vector2(-130.5,-68)
			#textbox.push_font_size(16)
#
		#1:
			#textbox.text = "Drag and Drop clothing items onto your player.
#
#Pass seven rounds to win it all!
#
#Press START to begin level one."
			#textbox.size = Vector2(284,102)
			#textbox.position = Vector2(-139,-62)
			#textbox.push_font_size(14)
#
		#2, 3, 4, 5, 6:
			#textbox.text
func _on_button_button_down() -> void:
	self.visible = false
	global.can_move_clothes = true
	
	# Don't need this anymore, but if we decide to have an option that re-enables the timer, we can reuse this
	#$"../Dressup Timer".get_child(0).start(10.0)
