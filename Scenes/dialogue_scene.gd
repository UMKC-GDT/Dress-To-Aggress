extends Node2D

@onready var characterLeft: Sprite2D = $Panel/CharacterLeft
@onready var characterRight: Sprite2D = $Panel/CharacterRight
@onready var textBox: Label = $Panel/Name/Text
@onready var nameBox: Label = $Panel/Name


var dialogue_script = []

var letter = 3
var line = 0

var nextScene
var sceneData
var dialogueFile
var inPosition

var scenes = ["uid://c4w3dm0al880e"]
var loseScenes = []

func _on_ready() -> void:
	if global.lostLastFight:
		sceneData = load(loseScenes[global.currentDialogueScene])
		global.currentDialogueScene = 0
	else:
		sceneData = load(scenes[global.currentDialogueScene])
		global.currentDialogueScene += 1
	dialogueFile = sceneData.getLinesFile()
	readFile(dialogueFile)
	$Panel/TextureRect.texture = sceneData.getBackground()
	nextScene = sceneData.getNextScene()
	characterLeft.texture = sceneData.getLeftCharacterModel()
	characterRight.texture = sceneData.getRightCharacterModel()
	
	if sceneData.getLeftCharacterShirt() == null or sceneData.getLeftCharacterPants() == null:
		var playerOutfit = load("res://Assets/Resources/OutfitSaveResource.tres")
		var playerShirt = load("res://Assets/Resources/Wearables/" + playerOutfit.shirt + ".tres")
		var playerPants = load("res://Assets/Resources/Wearables/" + playerOutfit.pants + ".tres")
		characterLeft.get_child(0).texture = playerShirt.mirrorPose
		characterLeft.get_child(0).modulate = playerShirt.color
		characterLeft.get_child(1).texture = playerPants.mirrorPose
		characterLeft.get_child(1).modulate = playerPants.color
	else:
		characterLeft.get_child(0).texture = sceneData.getLeftCharacterShirt()
		characterLeft.get_child(0).modulate = sceneData.getLeftCharacterShirtColor()
		characterLeft.get_child(1).modulate = sceneData.getLeftCharacterPantsColor()
		characterLeft.get_child(1).texture = sceneData.getLeftCharacterPants()
	
	if sceneData.getRightCharacterShirt() == null or sceneData.getRightCharacterPants() == null:
		pass
	else:
		characterRight.get_child(0).texture = sceneData.getRightCharacterShirt()
		characterRight.get_child(0).modulate = sceneData.getRightCharacterShirtColor()
		characterRight.get_child(1).texture = sceneData.getRightCharacterPants()
		characterRight.get_child(1).modulate = sceneData.getRightCharacterPantsColor()
		
	textBox.text = ""
	nameBox.text = ""
	
	$"animation Player".play("fadeOpen")


func _process(_delta):
	if inPosition:
		if line < dialogue_script.size() and letter < dialogue_script[line].length():
			textBox.text += dialogue_script[line][letter]
			letter += 1
			
		elif (Input.is_action_just_pressed("click") or Input.is_action_just_pressed("Space") or Input.is_action_just_pressed("player_punch")):
			line +=1
			letter = 3
			textBox.text = ""
		
		if line < dialogue_script.size() and dialogue_script[line][0] == "R":
			nameBox.text = sceneData.getRightCharacterName()
			characterRight.modulate =   Color(1.0, 1.0, 1.0)
			characterLeft.modulate = Color(0.494, 0.494, 0.494)
			
		elif line < dialogue_script.size() and dialogue_script[line][0] == "L":
			nameBox.text = sceneData.getLeftCharacterName()
			characterRight.modulate = Color(0.494, 0.494, 0.494)
			characterLeft.modulate = Color(1.0, 1.0, 1.0)
			
		elif line < dialogue_script.size() and dialogue_script[line][0] == "N":
			nameBox.text = ""
			characterRight.modulate = Color(0.494, 0.494, 0.494)
			characterLeft.modulate = Color(0.494, 0.494, 0.494)
			
		elif line == dialogue_script.size():
			textBox.text = ""
			nameBox.text = ""
			characterRight.modulate =Color(1.0, 1.0, 1.0)
			characterLeft.modulate = Color(1.0, 1.0, 1.0)
			$"animation Player".play("fadeScreen")

func moveNodes():
	$"animation Player".play("StartAnimation")
	
func setInPositionToTrue():
	inPosition = true

func toNextScene():
	global.lostLastFight = false
	get_tree().change_scene_to_file(nextScene)

func readFile(filePath):
	print("reading File")
	var file = FileAccess.open(filePath, FileAccess.READ)
	var content = file.get_as_text()
	var lineData = ""
	@warning_ignore("shadowed_global_identifier")
	for char in content:
		if char != "\n":
			lineData += char
		else:
			dialogue_script.append(lineData)
			lineData = ""
