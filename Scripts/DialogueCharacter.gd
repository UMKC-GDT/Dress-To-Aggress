class_name Dialogue
extends Resource

@export var linesFile: String 

@export_category("Right Character")
@export var rightName: String
@export var rightModel: Texture2D
@export var rightShirt: Texture2D
@export var rightPants: Texture2D
@export var rightShirtColor: Color
@export var rightPantsColor: Color

@export_category("Left Character")
@export var leftName: String
@export var leftModel: Texture2D
@export var leftShirt: Texture2D
@export var leftPants: Texture2D
@export var leftShirtColor: Color
@export var leftPantsColor: Color

func _init() -> void:
	pass


func getLinesFile(): return linesFile

func getRightCharacterName(): return rightName
func getRightCharacterModel(): return rightModel
func getRightCharacterShirt(): return rightShirt
func getRightCharacterPants(): return rightPants
func getRightCharacterShirtColor(): return rightShirtColor
func getRightCharacterPantsColor(): return rightPantsColor

func getLeftCharacterName(): return leftName
func getLeftCharacterModel(): return leftModel
func getLeftCharacterShirt(): return leftShirt
func getLeftCharacterPants(): return leftPants
func getLeftCharacterShirtColor(): return leftShirtColor
func getLeftCharacterPantsColor(): return leftPantsColor
