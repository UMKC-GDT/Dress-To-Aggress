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

@onready var rubyDialogueSFX: AudioStreamPlayer = $RubyDialogueSound
@onready var carnDialogueSFX: AudioStreamPlayer = $CarnDialogueSound
@onready var carnDialogueSFX2: AudioStreamPlayer = $CarnDialogueSound2


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

var dialog_state := "IDLE" # "IDLE", "TYPING", "WAITING"
var skip_typing := false

var preArcadeDialogue = [
	"R: Good to see you again, agent. It’s time for your next mission. Ever heard of a fashion brand called Astra?",
	"L: Uh, no?",
	"L: Uh, no?",
	"T: I don’t blame you; it’s not a particularly notable one.", 
	"R: Or so we thought.",
	"R: They’re holding showcases soon for a new line of high-tech clothes that enhance physical abilities.",
	"L: Why’s a fashion brand interested in something like that?",
	"T: Strange, right? It's even more strange how a brand without any significant revenue got the funding for this.",
	"R: We had agents tail some of their models, and we’re almost certain that there’s a crime syndicate behind them.",
	"L: Let me guess, smuggling?",
	"R: What else do crime syndicates do? Astra's hiring new models, so you must infiltrate their showcases undercover.",
	"R: You have to find out which of their offices is their headquarters so we can take them down.",
	"R: High Command says these clothes might be a cover for a new weapon, so prevention is vital.", 
	"R: With luck, it’ll be this first one, but if not, you’ll stay undercover and search their other locations.",
	"L: Quick question: Why am I the one doing this? I didn’t join this organization to model, you know.",
	"R: Well, no one else wanted it and you’re still new, so yeah. Have fun!",
	"L: *sigh*",
	"R: Oh, one more thing.",
	"R: Astra wants the models to test out the clothes while on the catwalk, so you’ll be doing some fighting, too.",
	"T: Try not to lose, okay? Can’t gather info if you’re knocked out.", 
	"L: I won't. I'll just have to dress to kill.",
	"R: Or I guess you could say you'll have to...",
	"L: Don't.",
	"R: Dress to...",
	"L: Carnelian i beg you",
	"T: ...Aggress?",
	"L: ...",
	"R: Like you're aggressive and attacking first?",
	"L: ..."
]

var dialogue1 = [
	"R: Here comes your first opponent!",
	"T: From the looks of it, she might just be a regular model…",
	"R: Well, you’ve gotta start somewhere!"
]

var dialogue2 = [
	"R: Nice work! I’ve verified your next opponent is definitely NOT a regular model.",
	"R: Watch her kicks and cover your eyes – those heels are sharp!"
]

var dialogue3 = [
	"R: Whew, I'm glad I'm not out there. These fights seem like a real workout.",
	"R: Get ready for this next one -- her green clothes absorb damage.",
	"T: Do you have a set that enhances your damage? Otherwise, this might take a while!"
]

var dialogue4 = [
	"R: Your next target is slippery. I can't keep track of people moving this quickly!",
	"R: Keep your distance, and don't let her overwhelm you. I’ll just check in with you once you’re done."
]

var dialogue5 = [
	"R: How’d the last fight go?",
	"L: Feeling dizzy now, but I won!",
	"T: Awesome! Get ready for this next one.",
	"R: We recognize her from our files. She's dangerous, and she loves striking poses.",
	"R: Remember that you can counter pose by posing first. It's a pose-off!"
]

var dialogue6 = [
	"R: These divas are dangerous! It’s like 1-2-3 with these girls, this one especially.",
	"R: Her dark clothes let her trap you in combos, so be careful.",
	"T: You’re almost there!"
]

var dialogue7 = [
	"L: Carnelian. I've made it to their headquarters, and my opponent's--",
	"R: Their highest-rated diva, and by the evidence you've sent, she's behind it all.",
	"R: You're almost at the top. Win this fashion show.",
	"R: Take down Astra once and for all, and remember everything you've learned.",
	"T: You'll need it!"
]

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
	
	setup_codec()

func setup_codec():
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

func explain_level_info() -> void:
	# make codec input active so _input() will respond
	codec_shown = true

	# prepare visuals
	await get_tree().create_timer(transition_time).timeout
	codecSprite.play("right talk")
	leftShadow.show()
	fullDialogueBox.hide()  # ensure the dialogue box isn't shown during this UI

	# -- Stage number --
	stageNumLabel.visible = true
	skip_typing = false
	dialog_state = "TYPING"
	await animate_text(stageNumLabel, text_speed)
	await get_tree().create_timer(transition_time).timeout

	# -- Difficulty label --
	difficultyLabel.visible = true
	skip_typing = false
	dialog_state = "TYPING"
	await animate_text(difficultyLabel, text_speed)
	await get_tree().create_timer(transition_time).timeout

	# -- Difficulty value --
	difficultyLabelTag.visible = true
	skip_typing = false
	dialog_state = "TYPING"
	await animate_text(difficultyLabelTag, text_speed)
	await get_tree().create_timer(transition_time).timeout

	# -- Style factor label --
	styleLabel.visible = true
	skip_typing = false
	dialog_state = "TYPING"
	await animate_text(styleLabel, text_speed)
	await get_tree().create_timer(transition_time).timeout

	# -- Style factor value --
	styleNumLabel.visible = true
	skip_typing = false
	dialog_state = "TYPING"
	await animate_text(styleNumLabel, text_speed)
	await get_tree().create_timer(transition_time).timeout

	# finished showing level info — go to waiting state
	codecSprite.play("idle")

	dialog_state = "WAITING"
	wait_for_input = true
	dialogueIndicator.show()

func _input(event: InputEvent) -> void:
	if not codec_shown:
		return

	# List of actions you want to use to skip/advance
	var advance_pressed := event.is_action_pressed("Space") \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("player_punch") \
		or event.is_action_pressed("click")

	if not advance_pressed:
		return

	# If we're currently typing, request immediate reveal
	if dialog_state == "TYPING":
		skip_typing = true
		return

	# If the line is finished and waiting for input, advance
	if dialog_state == "WAITING":
		# hide indicators, then start next line
		dialogueIndicator.hide()
		stageNumLabel.hide()
		difficultyLabel.hide()
		difficultyLabelTag.hide()
		styleLabel.hide()
		styleNumLabel.hide()

		dialog_state = "IDLE"            # temporarily set while we call next line
		run_codec_dialogue()
		return

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
	
	if global.arcade_level == -1:
		global.arcade_level = 1
		get_tree().change_scene_to_file("res://Scenes/DressUp.tscn")

func run_codec_dialogue():
	leftShadow.show()
	await get_tree().create_timer(transition_time).timeout
	fullDialogueBox.show()

	# If we're past the last line, clean up and return
	if line >= dialogue.size():
		fullDialogueBox.hide()
		await get_tree().create_timer(transition_time).timeout
		wait_for_input = false
		hide_codec()
		dialog_state = "IDLE"
		return

	# Prepare the correct side and text, then animate
	if dialogue[line][0] == "L":
		codecSprite.play("left talk")
		rubyDialogueSFX.play()
		fullDialogueBox.text = dialogue[line].substr(3, -1)
		rightShadow.show()
		leftShadow.hide()
		
	elif dialogue[line][0] == "R":
		codecSprite.play("right talk")
		carnDialogueSFX.play()
		fullDialogueBox.text = dialogue[line].substr(3, -1)
		rightShadow.hide()
		leftShadow.show()
	
	#NOTE! This might look really confusing, but this is the simplest and fastest way to use Carnelian's other facial expression by just specifying it in that line of dialogue.
	elif dialogue[line][0] == "T":
		codecSprite.play("right expression")
		carnDialogueSFX2.play()
		fullDialogueBox.text = dialogue[line].substr(3, -1)
		rightShadow.hide()
		leftShadow.show()

	# start typing
	dialog_state = "TYPING"
	skip_typing = false
	await animate_text(fullDialogueBox, text_speed/2)

	# after typing finishes
	dialog_state = "WAITING"
	rubyDialogueSFX.stop()
	carnDialogueSFX.stop()
	carnDialogueSFX2.stop()
	wait_for_input = true
	dialogueIndicator.show()
	# keep the stage/difficulty/style labels visible while waiting (if needed)
	line += 1

func animate_text(label_node: RichTextLabel, speed: float = 0.05) -> void:
	label_node.visible_characters = 0
	label_node.show()

	var char_count = label_node.text.length()
	for i in range(char_count):
		# if a skip was requested, reveal whole text immediately and stop the loop
		if skip_typing:
			label_node.visible_characters = char_count
			break

		label_node.visible_characters = i + 1

		# optional: insta-space handling (uncomment if desired)
		# if label_node.text[i] == " ":
		#     continue

		await get_tree().create_timer(speed).timeout

	# ensure skip flag is cleared (we handled it)
	skip_typing = false
