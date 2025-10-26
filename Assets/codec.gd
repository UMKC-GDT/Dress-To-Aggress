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

@onready var codecSprite: AnimatedSprite2D = $Panel/CodecAnimatedSprite
@onready var blackBackground: Panel = $Panel/SolidBlackBackground

@onready var speechLines: Node2D = $Panel/SpeechLines

@onready var leftShadow: Panel = $Panel/CodecAnimatedSprite/LeftShadow
@onready var rightShadow: Panel = $Panel/CodecAnimatedSprite/RightShadow


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
var finish_codec_sprite_y = 96
var finish_codec_sprite_yScale = 1.63

var start_bg_y = 360
var start_bg_ySize = 0
var finish_bg_y = 36
var finish_bg_ySize = 640

var preArcadeDialogue = [
	"R: Good to see you again, agent. It’s time for your next mission. Ever heard of a fashion brand called Astra?",
	"L: Uh, no?",
	"R: I don’t blame you; it’s not a particularly notable one, or so we thought anyway. They’re holding a showcase soon for this line of high-tech clothes they came up with.",
	"R: Apparently, they can enhance people's physical abilities.",
	"L: Why’s a fashion brand interested in something like that?",
	"R: Strange, right? It's even more strange how a brand without any significant revenue got the funding for this.",
	"R: We had agents tail some of their models, and we’re almost certain that there’s a crime syndicate behind them.",
	"L: Let me guess, smuggling?",
	"R: What else do crime syndicates do? Astra's hiring new models, so you must infiltrate their showcases undercover.",
	"R: You’re going to try to find out which of their offices is their headquarters, so we can take them down.", 
	"R: With luck, it’ll be this first one, but if not, you’ll stay undercover and search their other locations.",
	"L: Quick question: Why am I the one doing this? I didn’t join this organization to model, you know.",
	"R: Well, no one else wanted it and you’re still new, so yeah. Have fun!",
	"L: *sigh*",
	"R: Carnelian: Oh, one more thing.",
	"R: Astra wants the models to test out the clothes while on the catwalk, so you’ll be doing some fighting, too.",
	"R: Try not to lose, okay? Can’t gather info if you’re knocked out.",
	"L: I'm on it."
]

var dialogue1 = ["R: Snake we need you to take down this gang.", "L: Snake? Who's snake?", "R: Sorry, that's a different agent. You still have a mission to complete.", "L: I got it boss, this will be over soon.", "R: I'm on frequency 126.04 when you need me"]
var dialogue2 = []
var dialogue3 = []
var dialogue4 = []
var dialogue5 = []
var dialogue6 = []
var dialogue7 = []

var dialogue = []
var line = 0
var arrow_right_pos = Vector2(778, 370)
var arrow_left_pos = Vector2(500, 370)

var both_closed_tex = preload("res://Assets/Sprites/Codec Talking Frames/CodeDecBothMouthClosed.png")
var both_open_tex = preload("res://Assets/Sprites/Codec Talking Frames/CodeDecBothMouthOpen.png")
var left_open_tex = preload("res://Assets/Sprites/Codec Talking Frames/CodeDecLeftMouthOpen.png")
var right_expres_change = preload("res://Assets/Sprites/Codec Talking Frames/CodeDecRightChangeExpresssion.png")
var right_open_tex = preload("res://Assets/Sprites/Codec Talking Frames/CodeDecRightMouthOpen.png")

@export var transition_time = 0.4
@export var text_speed = 0.03

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if global.arcade_level != 0:
		start_codec()

func start_codec():
	#Get the stage number, the current difficulty, and the style text
	var stageNum = global.arcade_level
	
	var styleFactor = 0
	print(global.arcade_level)
	match global.arcade_level:
			-1:
				dialogue = preArcadeDialogue
			0:
				panel.hide()
				return
			1: 
				styleFactor = 0.6 
				dialogue = dialogue1
			2: 
				styleFactor = 0.8
				dialogue = dialogue2
			3: 
				styleFactor = 1.0
				dialogue = dialogue3
			4: 
				styleFactor = 1.1
				dialogue = dialogue4
			5: 
				styleFactor = 1.2
				dialogue = dialogue5
			6: 
				styleFactor = 1.3
				dialogue = dialogue6
			7: 
				styleFactor = 1.4
				dialogue = dialogue7

	
	stageNumLabel.text = "STAGE " + str(stageNum)
	match global.arcade_level:
		-1: difficultyLabelTag = easyLabel
		
		1: difficultyLabelTag = easyLabel
		2: difficultyLabelTag = easyLabel
		3: difficultyLabelTag = normalLabel
		4: difficultyLabelTag = normalLabel
		5: difficultyLabelTag = hardLabel
		6: difficultyLabelTag = hardLabel
		7: difficultyLabelTag = hardLabel
	
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
	leftShadow.hide()
	rightShadow.hide()

	#Call a function to animate showing the codec
	show_codec()

func show_codec():
	leftShadow.hide()
	#Animate the panel fading in?
	panel.show()
	
	codecSprite.play("idle")
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
	
	if global.arcade_level >= 1:
		explain_level_info()
	elif global.arcade_level == -1:
		run_codec_dialogue()

func explain_level_info():
	await get_tree().create_timer(transition_time).timeout
	codecSprite.play("right talk")
	leftShadow.show()
	
	#Show the stage number
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
	leftShadow.hide()
	codecSprite.play("idle")
	wait_for_input = true
	codec_shown = true

func hide_codec():
	fullDialogueBox.hide()
	leftShadow.hide()
	rightShadow.hide()
	dialogueIndicator.hide()
	
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
func _process(_delta: float) -> void:
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
				run_codec_dialogue()

func run_codec_dialogue():
	leftShadow.show()
	await get_tree().create_timer(transition_time).timeout
	fullDialogueBox.show()
	
	
	wait_for_input = true
	dialogue_shown = true
	
	if line < dialogue.size() and dialogue[line][0] == "L":
		codecSprite.play("left talk")
		fullDialogueBox.text = dialogue[line].substr(3, -1)
		animate_text(fullDialogueBox, text_speed/2)
		line += 1
		rightShadow.show()
		leftShadow.hide()
		
	elif line < dialogue.size() and dialogue[line][0] == "R":
		codecSprite.play("right talk")
		fullDialogueBox.text = dialogue[line].substr(3, -1)
		animate_text(fullDialogueBox, text_speed/2)
		line += 1
		rightShadow.hide()
		leftShadow.show()
		
	elif line >= dialogue.size():
			fullDialogueBox.hide()
			
			await get_tree().create_timer(transition_time).timeout
			wait_for_input = false
			hide_codec()

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
