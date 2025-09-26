extends Node2D



var dialogue_script = ["R: dakljfdlkjfa", "L: alkdjakldsjf", "R: adhfasdjflk", "L: dhfjkadshflkjsa"]

var letter = 3
var line = 0

func _process(delta):
	
	if line < dialogue_script.size() and letter < dialogue_script[line].length():
		$Panel/Text.text += dialogue_script[line][letter]
		letter += 1
		
	elif Input.is_action_just_pressed("click"):
		line +=1
		letter = 3
		$Panel/Text.text = ""
	
	if line < dialogue_script.size() and dialogue_script[line][0] == "R":
		$Panel/CharacterRight.modulate =   Color(1.0, 1.0, 1.0)
		$Panel/CharacterLeft.modulate = Color(0.494, 0.494, 0.494)
		
		
	if line < dialogue_script.size() and dialogue_script[line][0] == "L":
		$Panel/CharacterRight.modulate = Color(0.494, 0.494, 0.494)
		$Panel/CharacterLeft.modulate = Color(1.0, 1.0, 1.0)
		
	if line == dialogue_script.size():
		$Panel/CharacterRight.modulate =Color(1.0, 1.0, 1.0)
		$Panel/CharacterLeft.modulate = Color(1.0, 1.0, 1.0)
	
	
