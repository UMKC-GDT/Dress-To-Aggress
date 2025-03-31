extends CharacterBody2D
class_name BaseCharacterController

@export var player_type  = 0  # 0 = CPU, 1 = Player 1, 2 = Player 2
@export var enemy_name = "player1"  # Name of the enemy node

var movement_speed_mult = 1
var dash_speed_mult = 1
var dash_available = true
var jump_height_mult = 1
var jump_speed_mult = 1

var punch_speed_mult = 1
var punch_hitstun_mult = 1
var punch_knockback_mult = 1
var punch_damage_mult = 1

var kick_speed_mult = 1
var kick_hitstun_mult = 1
var kick_knockback_mult = 1
var kick_forward_mult = 1
var kick_damage_mult = 1

var pose_speed_mult = 1
var pose_hitstun_mult = 1
var pose_knockback_mult = 1
var pose_damage_mult = 1


@export var health = 100

# Based on the player type, in a later function, these'll be redefined or left empty depending on who's controlling it. This list will be expanded with each control.
var left_input = ""
var right_input = ""
var jump_input = ""
var punch_input = ""
var kick_input = ""
var pose_input = ""
var debug_hurt = ""

#At the heart of the player controller, this is the ENUM that defines all the current states the player can be in. This will get longer as more states are added, and this should be the first place you go to add a new state.
enum CharacterState { IDLE, WALK, JUMP, DASH, STARTUP, RECOVERY, PUNCH, KICK, HURT, BLOCK, POSE_STARTUP, POSE, DEAD, DISABLED}
var state = CharacterState.IDLE
var last_state = CharacterState.IDLE
var left_ground_check = false

@onready
var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready
var PantsLayer: AnimatedSprite2D = $PantsLayer
@onready
var ShirtLayer: AnimatedSprite2D = $ShirtLayer

@onready
var punch_hitbox: Hitbox = $"Punch Hitbox"

@onready
var kick_hitbox = $"Kick Hitbox"

@onready
var throw_hitbox: Hitbox = $"Throw Hitbox"


var enemy = null
var enemy_direction = 1

var direction := 0
var facing_direction = 1
var horizontal_distance = 0
var vertical_distance = 0

var dash_direction = 0
var dashes_left = 1

#This Frame constant defines a frame as one sixtieth of a second, for consistent timing, and it means attacks can be defined in terms of frames (3 frame startup, 5 frame active, etc) which is consistent with the typical mechanics of fighting games. 
# A surprise tool that'll help us later!
const FRAME = 1.0 / 60.0
var current_time = 0

var last_left_press_time = 0.0
var last_right_press_time = 0.0

var last_dash_time = 0.0
var dash_timer = 0.0

var cancellable = true

var block_legal = false
var block_timer = 0.0

var dead = false
var disabled = false

@export var DOUBLE_TAP_TIME = 0.2 # Time window for double tap detection
@export var DASH_TIME = 0.20 # Dash lasts 0.20 seconds, lengthen this for a longer dash.
@export var DASH_SPEED = 90 * dash_speed_mult # Set dash speed
@export var DASH_COOLDOWN = 0.2 # Half a second cooldown between valid dashes. This prevents the player from spamming dash across the screen, without stopping.
@export var MIDAIR_DASH = true

#Note for the below data: onBlock is positive because, if an attack is blocked, the player will transition to the RECOVERY state for (recovery + onBlock) frames. 
var attack_timer = 0.0
var punch_data = {
	"startup_frames" : 6 / punch_speed_mult,
	"active_frames" : 4,
	"recovery_frames" : 11 / punch_speed_mult,
	"blockstun_frames" : 11,
	"onBlock_FA" : -3,
	"ground_hitstun": 20 / punch_hitstun_mult,
	"air_hitstun" : 20 / punch_hitstun_mult,
	"ground_knockback_force" : 100 * punch_knockback_mult,
	"air_knockback_force" : 50 * punch_knockback_mult,
	"forward_force": 0,
	"damage": 10 * punch_damage_mult,
	"startup_animation" : "punch startup",
	"active_animation" : "punch",
	"recovery_animation" : "punch recovery",
}
var punch_deceleration = 10


var kick_data = {
	"startup_frames" : 14 / kick_speed_mult,
	"active_frames" : 6,
	"recovery_frames" : 20 / kick_speed_mult,
	"blockstun_frames" : 12,
	"onBlock_FA" : -12,
	"ground_hitstun": 22 * kick_hitstun_mult,
	"air_hitstun" : 22 * kick_hitstun_mult,
	"ground_knockback_force" : 200 * kick_knockback_mult,
	"air_knockback_force" : 100 * kick_knockback_mult,
	"forward_force": 100 * kick_forward_mult,
	"damage": 30 * kick_damage_mult,
	"startup_animation" : "kick startup",
	"active_animation" : "kick",
	"recovery_animation" : "kick recovery",
}

var throw_data = {
	"startup_frames" : 5 / pose_speed_mult,
	"active_frames" : 3,
	"recovery_frames" : 23 / pose_speed_mult,
	"pose_frames" : 60,
	"ground_hitstun": 77 * pose_hitstun_mult, # This value needs to be pose_frames + 17, so that the attacker has 17 frames of frame advantage for posing first.
	"ground_knockback_force" : 200 * pose_knockback_mult,
	"forward_force": 0,
	"damage": 20 * pose_damage_mult,
	"startup_animation" : "jump startup",
	"active_animation" : "pose",
	"recovery_animation" : "pose recovery",
}

#Defines the player's walk speed, and jump speeds.
@export var SPEED = 20.0 * movement_speed_mult
@export var VERTICAL_JUMP_VELOCITY = -250.0 * jump_height_mult
@export var HORIZONTAL_JUMP_VELOCITY = 70 * jump_speed_mult


func set_controls():
	match player_type:
		0: 
			print("CPU Controls Enabled. I won't do anything.")
		1:
			left_input = "player_left"
			right_input = "player_right"
			jump_input = "player_jump"
			punch_input = "player_punch"
			kick_input = "player_kick"
			pose_input = "player_throw"
			debug_hurt = "DEBUG_hurt_player"
			
			print("Player 1 Controls Enabled")
		2: 
			left_input = "player2_left"
			right_input = "player2_right"
			jump_input = "player2_jump"
			punch_input = "player2_punch"
			kick_input = "player2_kick"
			pose_input = "player2_throw"
			debug_hurt = "DEBUG_hurt_player2"
			
			print("Player 2 Controls Enabled")

func stop_all_timers():
	for child in get_children():
		if child is Timer:
			print(child)
			child.stop()

func apply_gravity(delta):
	
	if not is_on_floor():
		#We multiply gravity times 0.8 to make it slightly slower, so mess with this in tandem with the vertical jump velocity to change the player's jumping speed.
		velocity += (get_gravity() * 0.8) * delta

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	current_time = Time.get_ticks_msec() / 1000.0  # Time in seconds
	
	if dead: 
		animation_player.play("dead")
		PantsLayer.play("dead")
		ShirtLayer.play("dead")
	
	handle_input(delta)
	face_your_opponent()

func _ready():
	enemy = get_parent().get_node(enemy_name)
	
	if enemy == null:
		push_error("Enemy node '%s' not found!" % enemy_name)
	
	report_dead()
	
	set_controls()
	disable_hitboxes()
	#scale_stats()
	update_healthbar()

#This is the first function at the heart of the character controller functionality, called every frame. It handles taking in inputs, but also establishing what inputs are valid for each state, and calling the corresponding function for that state. 
func handle_input(delta):
	
	#Keeping this in the code instead of deleting it! This is great for debug. Enable it, and edit the print function, and receive whatever information you need relative to player1's character controller.
	#if (player_type == 1): print(state)
	
	if (not disabled) and Input.is_action_pressed(debug_hurt):
		#print("Disabling myself!")
		#disable_control()
		#get_hit_with(punch_data)
		pass
	
	if not disabled:
		if Input.is_action_just_pressed(left_input):
			direction = -1
		elif Input.is_action_just_pressed(right_input):
			direction = 1
		elif (state != CharacterState.DASH) and (direction == 1 and not Input.is_action_pressed(right_input)) or (direction == -1 and not Input.is_action_pressed(left_input)):
			direction = 0
	
	#This handles checking for the dash input, completely outside of the defined states below.
	check_for_dash()
	
	handle_states(direction, delta)

func handle_states(direction, delta):
	if direction == 0: block_legal = false
	
	if player_type == 1: print(horizontal_distance)
	
		#To add a new state, just add a new match case for that specific state, and similarly include the animation to be played and a call for that state's function. 
	match state:
		
		CharacterState.IDLE:
			animation_player.play("idle")
			PantsLayer.play("idle")
			ShirtLayer.play("idle")
			idle_state(direction)
			
		CharacterState.WALK:
			if facing_direction == 1:
				if direction == 1:
					animation_player.play("walk forward")
					PantsLayer.play("walk forward")
					ShirtLayer.play("walk forward")
				else:
					animation_player.play("walk backward")
					PantsLayer.play("walk backward")
					ShirtLayer.play("walk backward")
			elif facing_direction == -1:
				if direction == 1:
					animation_player.play("walk backward")
					PantsLayer.play("walk backward")
					ShirtLayer.play("walk backward")
				else:
					animation_player.play("walk forward")
					PantsLayer.play("walk forward")
					ShirtLayer.play("walk forward")
			
			if (direction == facing_direction * -1): block_legal = true
			else: block_legal = false
			
			walk_state(direction)
		
		CharacterState.JUMP:
			animation_player.play("jump")
			PantsLayer.play("jump")
			ShirtLayer.play("jump")
			jump_state(direction, delta)
		
		CharacterState.DASH:
			if dash_direction == 1:
				if facing_direction == -1: 
					animation_player.play("dash left")
					PantsLayer.play("dash left")
					ShirtLayer.play("dash left")
				else: 
					animation_player.play("dash right")
					PantsLayer.play("dash right")
					ShirtLayer.play("dash right")
			else:
				if facing_direction == -1:
					animation_player.play("dash right")
					PantsLayer.play("dash right")
					ShirtLayer.play("dash right")
				else: 
					animation_player.play("dash left")
					PantsLayer.play("dash left")
					ShirtLayer.play("dash left")
				
			dash_state(delta)
		
		CharacterState.STARTUP:
			block_legal = false
			#Noting this to remember later. Freezing the player's horizontal velocity during startup might be a problem. 
			if is_on_floor(): velocity.x = 0
		
		CharacterState.PUNCH:
			block_legal = false
			animation_player.play(punch_data["active_animation"])
			PantsLayer.play(punch_data["active_animation"])
			ShirtLayer.play(punch_data["active_animation"])
			punch_state(delta)
		
		CharacterState.KICK:
			block_legal = false
			animation_player.play(kick_data["active_animation"])
			PantsLayer.play(kick_data["active_animation"])
			ShirtLayer.play(kick_data["active_animation"])
			kick_state(delta)
		
		CharacterState.RECOVERY:
			block_legal = false
			if (is_on_floor()): velocity.x = move_toward(velocity.x, 0, punch_deceleration)
			if cancellable: check_for_attack()
			disable_hitboxes()
		
		CharacterState.HURT:
			block_legal = false
			disable_hitboxes()
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, 25)
		
		CharacterState.BLOCK:
			animation_player.play("block")
			PantsLayer.play("block")
			ShirtLayer.play("block")
			disable_hitboxes()
			block_state(delta)
		
		CharacterState.POSE_STARTUP:
			velocity.x = 0
		
		CharacterState.POSE:
			animation_player.play("pose")
			PantsLayer.play("pose")
			ShirtLayer.play("pose")
			disable_hitboxes()
			pose_state(delta)
		
		CharacterState.DEAD:
			animation_player.play("dead")
			PantsLayer.play("dead")
			ShirtLayer.play("dead")
			velocity.x = move_toward(velocity.x, 0, 25)
	
	move_and_slide()

#Every function below handles the actual logic for each state -- idle_state is called during the idle state, walk_state during the walk state, and so forth. As you could guess, each of those functions then define what can actually be done, and what inputs or conditions transfer us from state to state. 
func idle_state(direction):
	if is_on_floor():
		dashes_left = 1
		
		if direction: 
			change_state(CharacterState.WALK)
		else:
			
			if not disabled:
				check_for_jump()
			
			check_for_attack()
			check_for_pose()
			disable_hitboxes()
			
			cancellable = false
			
			velocity.x = move_toward(velocity.x, 0, 20)

func walk_state(direction):
	if direction == 0:
		change_state(CharacterState.IDLE)
	elif Input.is_action_pressed(jump_input) and is_on_floor():
		start_action(4, func(): start_jump(direction), "jump startup")
	else:
		velocity.x = direction * SPEED
		check_for_attack()
		check_for_pose()

func start_jump(direction):
	left_ground_check = false
		
	velocity.y = VERTICAL_JUMP_VELOCITY
	
	if direction:
		velocity.x = direction * HORIZONTAL_JUMP_VELOCITY
	else:
		velocity.x = 0
	
	change_state(CharacterState.JUMP)

func jump_state(direction, delta):
	if not left_ground_check and not is_on_floor():
		left_ground_check = true
	
	check_for_attack()
	
	if left_ground_check and is_on_floor():
		change_state(CharacterState.IDLE)
		print("Just landed!")

func start_dash(direction):
	dash_timer = DASH_TIME
	velocity.x = direction * DASH_SPEED
	if not is_on_floor():
		dashes_left = 0
	
	change_state(CharacterState.DASH)

func dash_state(delta):
	velocity.y = 0
	check_for_attack()
	check_for_pose()
	
	if dash_timer > 0:
		dash_timer -= delta
	else:
		last_dash_time = current_time
		change_state(CharacterState.IDLE)

#This is where the code goes for the moment the punch is active. LATER ON, add the sound effect in this function.
func start_punch():
	if (state != CharacterState.STARTUP): return
	
	attack_timer = punch_data["active_frames"] * FRAME
	velocity.x += punch_data["forward_force"] * facing_direction
	punch_hitbox.enable()
	cancellable = true
	
	change_state(CharacterState.PUNCH)

func punch_state(delta):
	if (is_on_floor()): velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		start_recovery(punch_data["recovery_frames"], punch_data["recovery_animation"])

#This is where the code goes for the moment the punch is active. LATER ON, add the sound effect in this function.
func start_kick():
	if (state == CharacterState.STARTUP): 
		attack_timer = kick_data["active_frames"] * FRAME
		velocity.x = kick_data["forward_force"] * facing_direction
		kick_hitbox.enable()
		
		cancellable = false
		
		change_state(CharacterState.KICK)

func kick_state(delta):
	velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		start_recovery(kick_data["recovery_frames"], kick_data["recovery_animation"])

#In block_state(), slow down at regular speed, decrement block_timer by delta until it's 0 and change_state(CharacterState.IDLE)
func block_state(delta):
	velocity.x = move_toward(velocity.x, 0, 20)
	
	if block_timer > 0:
		block_timer -= delta
	else:
		change_state(CharacterState.IDLE)

func start_recovery(frames, animation):
	#if (state != CharacterState.PUNCH) and (state != CharacterState.KICK): return
	if dead: return
	change_state(CharacterState.RECOVERY)
	
	animation_player.play(animation)
	PantsLayer.play(animation)
	ShirtLayer.play(animation)
	var wait_time = frames * FRAME
	var timer = get_tree().create_timer(wait_time)
	timer.timeout.connect(func(): if state != CharacterState.STARTUP and state != CharacterState.HURT: change_state(CharacterState.IDLE))

func get_hit_with(attack_data):
	change_state(CharacterState.HURT)
	
	animation_player.play("hurt")
	PantsLayer.play("hurt")
	ShirtLayer.play("hurt")
	velocity.y = 0
	velocity.x = 0
	
	reduce_health(attack_data["damage"])
	
	stop_all_timers()
	
	var wait_time = 0.0
	
	if is_on_floor():
		velocity.x = -1 * (facing_direction) * attack_data["ground_knockback_force"]
		wait_time = FRAME * attack_data["ground_hitstun"]
		stop_all_timers()
	else:
		stop_all_timers()
		velocity.y = -1 * attack_data["air_knockback_force"]
		velocity.x = -1 * (facing_direction) * attack_data["air_knockback_force"]
		
		wait_time = FRAME * attack_data["air_hitstun"]
	
	var timer = get_tree().create_timer(wait_time)
	timer.timeout.connect(func(): change_state(CharacterState.IDLE))

func start_action(frames, continuation, animation):
	change_state(CharacterState.STARTUP)
	
	animation_player.play(animation)
	PantsLayer.play(animation)
	ShirtLayer.play(animation)
	
	var wait_time = frames * FRAME
	var timer = get_tree().create_timer(wait_time)
	#print("Creating a timer for " + str(wait_time))
	timer.timeout.connect(continuation)

#When you press throw, enter POSE_STARTUP, then, after startup_frames, trigger POSE hitbox
func start_pose():
	change_state(CharacterState.POSE_STARTUP)
	
	animation_player.play(throw_data["startup_animation"])
	PantsLayer.play(throw_data["startup_animation"])
	ShirtLayer.play(throw_data["startup_animation"])
	
	var wait_time = throw_data["startup_frames"] * FRAME
	var timer = get_tree().create_timer(wait_time)
	timer.timeout.connect(func(): throw_hitbox.enable())

#In pose(), enter POSE state. If the parameter is null, start_recovery() with POSE animation for recovery_frames. If it's not null, call target's get_hit_with() with the data of my throw, and then start_recovery() with POSE animation for pose_frames 
func pose(target):
	change_state(CharacterState.POSE)
	
	if target == null:
		start_recovery(throw_data["recovery_frames"], throw_data["active_animation"])
	else:
		if target.has_method("get_hit_with"):
			target.get_hit_with(throw_data)
			start_recovery(throw_data["pose_frames"], throw_data["active_animation"])

#In pose_broken(), enter POSE state, get knocked back slightly, and then start_recovery for recovery_frames / 2
func pose_broken():
	change_state(CharacterState.POSE)
	
	velocity.x = -1 * (facing_direction) * 100
	
	start_recovery((throw_data["recovery_frames"] / 2.0), throw_data["active_animation"])

func pose_state(delta):
	velocity.x = move_toward(velocity.x, 0, 20)

#Mostly for debug. Updates the character state and prints it to the console. 
func change_state(new_state):
	if dead: return
	last_state = state
	state = new_state
	print(str(player_type) + ": Character State Updated: " + CharacterState.keys()[state])

func check_for_attack():
	if disabled == true: 
		return
	
	
	if Input.is_action_pressed(punch_input):
		stop_all_timers()
		start_action(punch_data["startup_frames"], func(): 
			if state == CharacterState.STARTUP:
				start_punch()
			, punch_data["startup_animation"])
	
	if Input.is_action_pressed(kick_input):
		stop_all_timers()
		start_action(kick_data["startup_frames"], func(): 
			if state == CharacterState.STARTUP:
				start_kick()
			, kick_data["startup_animation"])

func check_for_pose():
	if disabled: return
	
	if Input.is_action_pressed(pose_input):
		stop_all_timers()
		start_pose()

func check_for_dash():
	
	if (dash_available == false): return
	if disabled: return
	
	if state == CharacterState.IDLE or state == CharacterState.WALK or state == CharacterState.JUMP:
		if Input.is_action_just_pressed(left_input):
			if current_time - last_left_press_time <= DOUBLE_TAP_TIME:
				if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN): #check that dash is off cooldown
					if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
						start_dash(-1)
				dash_direction = -1
			last_left_press_time = current_time
		
		if Input.is_action_just_pressed(right_input):
			if current_time - last_right_press_time <= DOUBLE_TAP_TIME:
				if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN):
					if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
						start_dash(1)
				dash_direction = 1
			last_right_press_time = current_time

func check_for_jump():
	if Input.is_action_pressed(jump_input):
		start_action(4, func(): start_jump(0), "jump startup")

func attack_hit(target):
	
	if target.has_method("get_hit_with"):
		match state:
			CharacterState.PUNCH:
				print("Hitting " + str(target) + " with the almighty punch!")
				target.get_hit_with(punch_data)
			
			CharacterState.KICK:
				print("Hitting " + str(target) + " with the almighty kick!")
				target.get_hit_with(kick_data)

func reduce_health(damage):
	health -= damage
	print(str(player_type) + ": Taken damage.")
	
	#This is where the code would go for playing a hurt sound effect -- IF I HAD ONE!!
	update_healthbar()
	
	if health <= 0:
		disable_hitboxes()
		stop_all_timers()
		
		change_state(CharacterState.DEAD)
		rotation_degrees = 90
		
		# Force collision update
		set_deferred("disabled", true)
		await get_tree().process_frame
		set_deferred("disabled", false)
		
		#This is where we handle reporting to the overarching game controller that we're dead, and the round is over...IF WE HAD SOME!!
		report_dead()
		
		print("Welp, guess I'm dead!")
		dead = true

func disable_hitboxes():
	for child in get_children():
		if child is Hitbox:
			child.disable()

func face_your_opponent():
	if not (state == CharacterState.IDLE or state == CharacterState.WALK): return
	 
	#if player_type == 1: print(vertical_distance)
	enemy_direction = sign(enemy.global_position.x - global_position.x)
	horizontal_distance = abs(enemy.global_position.x - global_position.x)
	vertical_distance = enemy.global_position.y - global_position.y
	
	if (horizontal_distance < 10) and (vertical_distance > 19) and is_on_floor():
		print("I'm standing on top of him.") 
		velocity.y = -30
		velocity.x = facing_direction * -1 * 90
	if (horizontal_distance < 0.5) and (vertical_distance > 19) and is_on_floor():
		print("RANDOM BULLSHIT GO")
	elif enemy_direction != 0 and enemy_direction != facing_direction and not (horizontal_distance < 0.5):
		print("My opponent's on the other side. Flipping!")
		scale.x *= -1
		facing_direction *= -1

#Attack_Was_Blocked() -- Start recovery for recovery frames + onBlockFA * -1, call opponent's Block_Attack(), negate horizontal speed
func attack_was_blocked(target):
	velocity.x = 0
	
	if target.has_method("block_attack"):
		match state:
			CharacterState.PUNCH:
				print("Target, " + str(target) + " has blocked my punch!")
				target.block_attack(punch_data)
				start_recovery((punch_data["recovery_frames"] + (-1 * punch_data["onBlock_FA"])), punch_data["recovery_animation"])
			
			CharacterState.KICK:
				print("Target, " + str(target) + " has blocked my kick!")
				target.block_attack(kick_data)
				print((kick_data["recovery_frames"] + (-1 * kick_data["onBlock_FA"])))
				start_recovery((kick_data["recovery_frames"] + (-1 * kick_data["onBlock_FA"])), kick_data["recovery_animation"])

#When we're the ones blocking an attack, set state to BLOCK, take negative x velocity of half of the attack's knockback, set block_timer to the given attack's blockstun frames
func block_attack(attack_data):
	change_state(CharacterState.BLOCK)
	velocity.x = -1 * (facing_direction) * attack_data["ground_knockback_force"] / 2
	block_timer = attack_data["blockstun_frames"] * FRAME

func update_healthbar():
	#This is where we'd call on the UI to update the reduced health -- IF I HAD ONE!!
	print(str(player_type) + ": Health: " + str(health))

func disable_control():
	disabled = true
	
	left_input = ""
	right_input = ""
	jump_input = ""
	punch_input = ""
	kick_input = ""
	pose_input = ""
	debug_hurt = ""

func enable_control():
	disabled = false
	set_controls()

'''
func scale_stats():
	movement_speed_mult = 
	dash_speed_mult = 
	dash_available =
	jump_height_mult =
	jump_speed_mult =

	punch_speed_mult = 
	punch_hitstun_mult = 
	punch_knockback_mult = 
	punch_damage_mult = 

	kick_speed_mult = 
	kick_hitstun_mult = 
	kick_knockback_mult = 
	kick_forward_mult = 
	kick_damage_mult = 

	pose_speed_mult = 
	pose_hitstun_mult = 
	pose_knockback_mult = 
	pose_damage_mult = '''

func report_dead():
	pass
