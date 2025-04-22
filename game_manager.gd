extends Node2D

@onready var message_label = $Message
@onready var message_timer = $"Message/Message Timer"

@onready var victory_label = $"Victory Message"

@onready var fight_timer_display = $"Fight Timer Display"
@onready var fight_timer = $"Fight Timer Display/Fight Timer"
@onready var player = $"../Player"
@onready var cpu = $"../Player2"

var timer_started := false

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
	await get_tree().create_timer(1.5).timeout
	
	animate_message_label("FIGHT!")
	await get_tree().create_timer(1.0).timeout
	
	message_label.text = ""
	player.disabled = false
	cpu.disabled = false
	fight_timer.start()
	timer_started = true

func end_round(condition):
	disable_control()
	fight_timer.paused = true
	
	if condition == 0: #If the player's lost...
		animate_message_label("KO!")
		
		await get_tree().create_timer(1.5).timeout
		victory_label.text = "You lose!"
		message_timer.start()
	elif condition == 1: #But, if the player's won...!
		animate_message_label("KO!")
		
		await get_tree().create_timer(1.5).timeout
		victory_label.text = "You win!"
		message_timer.start()
	else: #But, the secret third option -- a timeout??
		message_label.text = "TIME!"
		
		player.disabled = true
		cpu.disabled = true
		fight_timer.paused = true
		
		await get_tree().create_timer(2.5).timeout
		
		if player.health > cpu.health:
			cpu.reduce_health(1000000000)
		elif cpu.health < player.health:
			player.reduce_health(1000000000)
		elif cpu.health == player.health:
			# sudden death
			var rng = randi() % 2
			if rng == 0:
				player.reduce_health(1000000000)
			else:
				cpu.reduce_health(1000000000)

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

func _on_player_one_died() -> void:
	end_round(0)

func _on_cpu_died() -> void:
	end_round(1)

func _on_timer_timeout() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/DressUp.tscn")

func _on_fight_timer_timeout() -> void:
	end_round(3)
