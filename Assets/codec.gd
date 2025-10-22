extends Node2D

@onready var panel: Panel = $Panel

@onready var stageNumLabel: RichTextLabel = $Panel/StageNumLabel

@onready var difficultyLabel: RichTextLabel = $Panel/DifficultyLabel
@onready var difficultyLabelTag: RichTextLabel = null

@onready var easyLabel: RichTextLabel = $Panel/EasyLabelTag
@onready var normalLabel: RichTextLabel = $Panel/MediumLabelTag
@onready var hardLabel: RichTextLabel = $Panel/HardLabelTag

@onready var styleLabel: RichTextLabel = $Panel/StyleLabel
@onready var styleNumLabel: RichTextLabel = $Panel/StyleNumLabel

@onready var fullDialogueBox: RichTextLabel = $Panel/FullDialogueBox
@onready var dialogueIndicator: RichTextLabel = $Panel/DialogueIndicator

@onready var codecSprite: Sprite2D = $Panel/CodeDecDta2
@onready var blackBackground: Panel = $Panel/SolidBlackBackground

@onready var speechLines: Node2D = $Panel/SpeechLines

var stageText = "STAGE X"
var difficultyText = "DIFFICULTY:"
var styleText = "STYLE FACTOR:"

var sentence_index = 0
var active_label

var wait_for_input = false
var codec_shown = true
var dialogue_shown = false

#Values for animating
var start_codec_sprite_y = 360.497
var start_codec_sprite_yScale = 0
var finish_codec_sprite_y = 200
var finish_codec_sprite_yScale = 0.994

var start_bg_y = 360
var start_bg_ySize = 0
var finish_bg_y = 36
var finish_bg_ySize = 640

@export var transition_time = 0.4
@export var text_speed = 0.03

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#Get the stage number, the current difficulty, and the style text
	var stageNum = global.arcade_level
	
	var styleFactor = 0
	match global.arcade_level:
			1: styleFactor = 0.6
			2: styleFactor = 0.8
			3: styleFactor = 1.0
			4: styleFactor = 1.1
			5: styleFactor = 1.2
			6: styleFactor = 1.3
			7: styleFactor = 1.4
	
	if global.arcade_level == 0:
		panel.hide()
		return
	
	stageNumLabel.text = "STAGE " + str(stageNum)
	match global.difficulty:
		"Easy":
			difficultyLabelTag = easyLabel
		"Normal":
			difficultyLabelTag = normalLabel
		"Hard":
			difficultyLabelTag = hardLabel
	
	styleNumLabel.text = str(styleFactor + 0.0) + "X"
	
	stageNumLabel.hide()
	difficultyLabel.hide()
	difficultyLabelTag.hide()
	styleLabel.hide()
	styleNumLabel.hide()
	panel.hide()
	dialogueIndicator.hide()
	fullDialogueBox.hide()
	codecSprite.hide()
	blackBackground.hide()
	speechLines.hide()

	#Call a function to animate showing the codec
	show_codec()

func show_codec():
	#Animate the panel fading in?
	panel.show()
	await get_tree().create_timer(transition_time).timeout
	
	#Right here, animate lerping between the intended values for the effect you want
	blackBackground.position = Vector2(blackBackground.position.x, start_bg_y)
	blackBackground.size.y = start_bg_ySize
	
	codecSprite.position = Vector2(codecSprite.position.x, start_codec_sprite_y)
	codecSprite.scale.y = start_codec_sprite_yScale
	
	blackBackground.show()
	codecSprite.show()
	
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(blackBackground, "position", Vector2(blackBackground.position.x, finish_bg_y), transition_time)
	tween.tween_property(blackBackground, "size", Vector2(blackBackground.size.x, finish_bg_ySize), transition_time)
	
	# Animate the Sprite
	tween.tween_property(codecSprite, "position", Vector2(codecSprite.position.x, finish_codec_sprite_y), transition_time)
	tween.tween_property(codecSprite, "scale", Vector2(codecSprite.scale.x, finish_codec_sprite_yScale), transition_time)
	
	begin_codec()

func begin_codec():
	
	
	#Show the stage number
	await get_tree().create_timer(transition_time).timeout
	speechLines.show()
	
	await animate_text(stageNumLabel, text_speed)
	
	await get_tree().create_timer(transition_time).timeout
	
	#Show the difficulty label
	await animate_text(difficultyLabel, text_speed)
	
	await get_tree().create_timer(transition_time).timeout
	
	#Show the difficulty
	await animate_text(difficultyLabelTag, text_speed)
	
	await get_tree().create_timer(transition_time).timeout
	
	#Show the style factor label
	await animate_text(styleLabel, text_speed)
	
	await get_tree().create_timer(transition_time).timeout
	
	#Show the style factor
	await animate_text(styleNumLabel, text_speed)
	
	await get_tree().create_timer(transition_time).timeout
	
	#Wait until the player presses any of the buttons...
	wait_for_input = true
	codec_shown = true

func hide_codec():
	fullDialogueBox.hide()
	speechLines.hide()
	
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(blackBackground, "position", Vector2(blackBackground.position.x, start_bg_y), transition_time)
	tween.tween_property(blackBackground, "size", Vector2(blackBackground.size.x, start_bg_ySize), transition_time)
	
	# Animate the Sprite
	tween.tween_property(codecSprite, "position", Vector2(codecSprite.position.x, start_codec_sprite_y), transition_time)
	tween.tween_property(codecSprite, "scale", Vector2(codecSprite.scale.x, start_codec_sprite_yScale), transition_time)
	
	await get_tree().create_timer(transition_time).timeout
	panel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if wait_for_input:
		dialogueIndicator.show()
		
		if codec_shown:
			if Input.is_action_just_pressed("Space") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("player_punch")  or Input.is_action_just_pressed("click"):
				dialogueIndicator.hide()
				stageNumLabel.hide()
				difficultyLabel.hide()
				difficultyLabelTag.hide()
				styleLabel.hide()
				styleNumLabel.hide()
				wait_for_input = false
				
				#Once we have pre-fight lines, use this one. Otherwise...
				#continue_codec()
				hide_codec()
		
		if dialogue_shown:
			if Input.is_action_just_pressed("Space") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("player_punch") or Input.is_action_just_pressed("click"):
				fullDialogueBox.hide()
				
				await get_tree().create_timer(transition_time).timeout
				wait_for_input = false
				hide_codec()

func continue_codec():
	await get_tree().create_timer(transition_time).timeout
	fullDialogueBox.show()
	
	#This is where we animate the dialogue
	animate_text(fullDialogueBox, (text_speed / 2))
	
	await get_tree().create_timer(2).timeout
	wait_for_input = true
	dialogue_shown = true

# Animates a label's text, letter by letter.
# This function assumes the label's 'text' property is already set.
func animate_text(label_node: RichTextLabel, speed: float = 0.05):
	# 1. Set visible characters to 0 and show the label
	label_node.visible_characters = 0
	label_node.show()
	
	# 2. Get the total number of characters
	var char_count = label_node.text.length()
	
	# 3. Loop to reveal one character at a time
	for i in range(char_count):
		label_node.visible_characters = i + 1
		
		# Optional: uncomment this to make spaces appear instantly
		# if label_node.text[i] == " ":
		#	 continue 
			
		await get_tree().create_timer(speed).timeout
