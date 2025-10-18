extends Button

@export var InstructionsBoard: Sprite2D

func _ready() -> void:
	# Just in case
	if (InstructionsBoard.visible):
		visible = false;
	else:
		visible = true;
		
	match global.arcade_level:
		0:
			self.text = "START"
			self.size = Vector2(173,90)
			self.position = Vector2(386,167)
		1: 
			self.text = "START LEVEL ONE"
			self.size = Vector2(423,90)
			self.position = Vector2(136,167)
		2:
			self.text = "START LEVEL TWO"
			self.size = Vector2(423,90)
			self.position = Vector2(136,167)
		3:
			self.text = "START LEVEL THREE"
			self.size = Vector2(463,90)
			self.position = Vector2(96,167)
		4:
			self.text = "START LEVEL FOUR"
			self.size = Vector2(446,90)
			self.position = Vector2(113,167)
		5:
			self.text = "START LEVEL FIVE"
			self.size = Vector2(438,90)
			self.position = Vector2(121,167)
		6:
			self.text = "START LEVEL SIX"
			self.size = Vector2(417,90)
			self.position = Vector2(142,167)
		7: 
			self.text = "START FINAL LEVEL!"
			self.size = Vector2(494,90)
			self.position = Vector2(64,167)

func _on_button_button_down() -> void:
	visible = true
