extends Node2D

@onready var message_label = $Message
@onready var message_timer = $"Message/Message Timer"

@onready var victory_label = $"Victory Message"

@onready var fight_timer_display = $"Fight Timer Display"
@onready var fight_timer = $"Fight Timer Display/Fight Timer"
@onready var player = $"../Player"
@onready var cpu = $"../Player2"
@onready var controls_panel = $"Controls Panel"

@onready var fight_music = $"../Background Track"

var timer_started := false

# These messages get randomly chosen from, once the player wins or loses.
var loss_messages = [
	"That outfit? A fashion disaster.",
	"You lost the fight... and the runway.",
	"Guess style isn't everything.",
	"Back to the dressing room!",
	"You fought like a clearance rack."
]

var win_messages = [
	"Flawless and fashionable.",
	"SLAYYYY",
	"Victory looks good on you.",
	"They couldn’t handle the drip.",
	"Styled to kill"
]

#Like others in this script, this is just a small helper function so we won't have to write these same two lines twice.
func disable_control():
	player.disabled = true
	cpu.disabled = true

func _ready() -> void:
	randomize() #Apparently, this is a surprise tool that'll help us later with generating a certain random number.
	
	message_label.text = ""
	fight_timer_display.text = "99"
	victory_label.text = ""
	
	disable_control()
	start_round()

# Called at the beginning of the round, to do the fun and cool stuff like "READY? FIGHT!". 
func start_round() -> void:
	message_label.text = "READY?"
	await get_tree().create_timer(0.3).timeout
	
	# Slide in the controls panel from Y=200 to Y=55
	controls_panel.position.y = 200
	var tween := create_tween()
	tween.tween_property(controls_panel, "position", Vector2(controls_panel.position.x, 55), 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Wait for either 10 seconds, or for the player to press the punch button.
	await wait_for_controls_acknowledgement()
	
	begin_fight()
	
	#Slides the controls back down, off the screen.
	var tween_out := create_tween()
	tween_out.tween_property(controls_panel, "position", Vector2(controls_panel.position.x, -100), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween_out.finished

func begin_fight():
	
	#Turns out, 1.3 seconds in is the EXACT point we need to play from, to have the "FIGHT!" in the song line up with the FIGHT text.
	fight_music.play(1.3)
	animate_message_label("FIGHT!")
	await get_tree().create_timer(1.0).timeout
	
	message_label.text = ""
	player.disabled = false
	cpu.disabled = false
	fight_timer.start()
	
	timer_started = true

#Called above, just makes it wait for ten seconds or until the player presses Punch, to give them the time to read the controls. 
func wait_for_controls_acknowledgement() -> void:
	var timer := get_tree().create_timer(10.0)
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("player_punch") or Input.is_action_just_pressed("ui_accept"): 
			return
		if timer.time_left <= 0.0:
			return

func end_round(condition):
	disable_control()
	fight_timer.paused = true
	
	if condition == 0: #If the player's lost...
		animate_message_label("KO!")
		
		await get_tree().create_timer(1.0).timeout
		victory_label.text = loss_messages[randi() % loss_messages.size()]
		message_timer.start()
	elif condition == 1: #But, if the player's won...!
		animate_message_label("KO!")
		
		await get_tree().create_timer(1.0).timeout
		victory_label.text = win_messages[randi() % win_messages.size()]
		message_timer.start()
	else: #But, the secret third option -- a timeout?? Handles that logic.
		message_label.text = "TIME!"
		
		player.disabled = true
		cpu.disabled = true
		fight_timer.paused = true
		
		await get_tree().create_timer(2.5).timeout
		
		if player.health > cpu.health:
			cpu.reduce_health(1000000000)
		elif cpu.health < player.health:
			player.reduce_health(1000000000)
		elif cpu.health == player.health: #If, somehow, they tie in health, we'll flip a coin and give them a random fifty fifty shot on who dies.
			# sudden death
			var rng = randi() % 2
			if rng == 0:
				player.reduce_health(1000000000)
			else:
				cpu.reduce_health(1000000000)

#Called often above to animate the message label with its popout effect.
func animate_message_label(text):
	message_label.text = text
	message_label.scale = Vector2(0.5, 0.5)
	message_label.set_pivot_offset(message_label.size / 2)
	
	var tween := create_tween()
	tween.tween_property(message_label, "scale", Vector2(1.5, 1.5), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(message_label, "scale", Vector2(1, 1), 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	if timer_started:
		fight_timer_display.text = str(fight_timer.time_left).pad_decimals(1)

#Functions to handle incoming signals and call the according end round condition, or transition to the next part of the game. 
func _on_player_one_died() -> void:
	end_round(0)

func _on_cpu_died() -> void:
	end_round(1)

func _on_timer_timeout() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/DressUp.tscn")

func _on_fight_timer_timeout() -> void:
	end_round(3)
