extends Node2D

@onready var stageNumLabel: Label = $Panel/StageNumLabel
@onready var difficultyLabel: Label = $Panel/DifficultyLabel
@onready var difficultyLabelTag: Label = $Panel/DifficultyLabelTag
@onready var styleLabel: Label = $Panel/StyleLabel
@onready var styleNumLabel: Label = $Panel/StyleNumLabel

@onready var fullDialogueBox: Label = $Panel/FullDialogueBox

var stageText = "STAGE X"
var difficultyText = "DIFFICULTY:"
var styleText = "STYLE FACTOR:"

var sentence_index = 0
var active_label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#Get the stage number, the current difficulty, and the style text
	
	#Call a function to animate showing the codec
	
	#Set the active text
	
	#Call the "begin dialogue" function
	
	pass # Replace with function body.

func begin_codec():
	#Show the stage number
	
	#Show the difficulty label
	
	#Show the difficulty
	
	#Show the style factor label
	
	#Show the style factor
	
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#check for if the player hits an input, if they do, just show all of the difficulty labels and set a boolean to true
	
	#if that boolean is true, then if they hit a button, we hide all of them 
	#then call a function to show the full dialogue box
	
	
	pass

func _on_timer_timeout() -> void:
	#Every time that the timer is out, check that the sentence index is less than the length of the active sentence. If so, add that index of the sentence to the active sentence's label. Otherwise, if it's equal to the length of the active sentence, then we run a function to change the active label.
	
	pass # Replace with function body.

func update_active_label():
	#Here, we check what the current active label is, and based on that, set it to another. 
	
	pass
