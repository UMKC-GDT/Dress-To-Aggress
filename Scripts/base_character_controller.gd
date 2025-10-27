extends CharacterBody2D
class_name BaseCharacterController

@export var player_type  = 0  # 0 = CPU, 1 = Player 1, 2 = Player 2
@export var enemy_name = "player1"  # Name of the enemy node

var hit_block_slowdown = false
var original_speed = 0

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

var health_mult = 1

var temperature = 1

@export var health = 200
var starting_health = 0
@export var health_UI : RichTextLabel
@export var healthbar: Node = null  # expects your Healthbar script

# Based on the player type, in a later function, these'll be redefined or left empty depending on who's controlling it. This list will be expanded with each control.
var left_input = ""
var right_input = ""
var jump_input = ""
var punch_input = ""
var kick_input = ""
var pose_input = ""
var crouch_input = ""
var debug_hurt = ""

#At the heart of the player controller, this is the ENUM that defines all the current states the player can be in. This will get longer as more states are added, and this should be the first place you go to add a new state.
enum CharacterState { IDLE, WALK, JUMP, DASH, STARTUP, RECOVERY, PUNCH, KICK, HURT, BLOCK, POSE_STARTUP, POSE, DEAD, DISABLED, CROUCH, CPUNCH, CKICK, CBLOCK}
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
var hurtbox: Hurtbox = $"Hurtbox"
var hurtboxRectangle: RectangleShape2D
var hurtboxCollision

@onready
var collision: CollisionShape2D = $"CollisionShape2D"

@onready
var punch_hitbox: Hitbox = $"Punch Hitbox"
@onready
var kick_hitbox = $"Kick Hitbox"
@onready
var throw_hitbox: Hitbox = $"Throw Hitbox"
@onready
var l_punch_hitbox: CrouchHitbox = $"LPunch Hitbox"
@onready 
var l_kick_hitbox: CrouchHitbox = $"LKick Hitbox"


var enemy = null
var enemy_direction = 1

var direction := 0
var facing_direction = 1
var horizontal_distance = 0
var vertical_distance = 0

var dash_direction = 0
var dashes_left = 1

# This Frame constant defines a frame as one sixtieth of a second, for consistent timing, and it means attacks can be defined in terms of frames (3 frame startup, 5 frame active, etc) which is consistent with the typical mechanics of fighting games. 
# A surprise tool that'll help us later!
const FRAME = 1.0 / 60.0
var current_time = 0

var last_left_press_time = 0.0
var last_right_press_time = 0.0

var last_dash_time = 0.0
var dash_timer = 0.0

var cancellable = true

var block_legal = false
var crouch_block_legal = false
var block_timer = 0.0

var dead = false
var disabled = false

@export var DOUBLE_TAP_TIME = 0.2 # Time window for double tap detection
@export var DASH_TIME = 0.09 # Dash lasts 0.20 seconds, lengthen this for a longer dash.
@export var DASH_SPEED = 180 * dash_speed_mult # Set dash speed
@export var DASH_COOLDOWN = 0.2 # Half a second cooldown between valid dashes. This prevents the player from spamming dash across the screen, without stopping.
@export var MIDAIR_DASH = true

#Note for the below data: onBlock is positive because, if an attack is blocked, the player will transition to the RECOVERY state for (recovery - onBlock) frames. 
var attack_timer = 0.0
var punch_data = {
	"startup_frames" : 4.0 / punch_speed_mult, #Dictates how long after pressing the button until the attack actually comes out
	"active_frames" : 3, #How long is the attack's hitbox/animation active?
	"recovery_frames" : 7.0 / punch_speed_mult, #Dictates how long AFTER the attack until the player can act again
	"blockstun_frames" : 9, #How long that a blocking opponent will be stuck blocking. 
	"onBlock_FA" : -1, #A little more complex, but this decides how much we're vulnerable when our attack is blocked. Keep it negative and increase this number to increase the window that it can be punished.
	"ground_hitstun": 24.0 / punch_hitstun_mult, #How long will the opponent be stunned in pain after getting hit?
	"air_hitstun" : 24.0 / punch_hitstun_mult,
	"ground_knockback_force" : 150 * punch_knockback_mult,
	"air_knockback_force" : 50 * punch_knockback_mult,
	"forward_force": 50, #How far do WE lunge forward to attack?
	"damage": 10 * punch_damage_mult,
	"startup_animation" : "punch recovery",
	"active_animation" : "punch",
	"recovery_animation" : "punch recovery",
}
var punch_deceleration = 10

var crouch_punch_data = {
	"startup_frames" : 4.0 / punch_speed_mult,
	"active_frames" : 2.0,
	"recovery_frames" : 9.0 / punch_speed_mult,
	"blockstun_frames" : 10,
	"onBlock_FA" : -1,
	"ground_hitstun": 24.0 / punch_hitstun_mult,
	"air_hitstun" : 24.0 / punch_hitstun_mult,
	"ground_knockback_force" : 150 * punch_knockback_mult,
	"air_knockback_force" : 50 * punch_knockback_mult,
	"forward_force": 50,
	"damage": 10 * punch_damage_mult,
	"startup_animation" : "crouch punch recovery",
	"active_animation" : "crouch punch",
	"recovery_animation" : "crouch punch recovery",
}
var crouch_punch_deceleration = 10


var kick_data = {
	"startup_frames" : 12.0 / kick_speed_mult,
	"active_frames" : 4,
	"recovery_frames" : 20.0 / kick_speed_mult,
	"blockstun_frames" : 24,
	"onBlock_FA" : -19,
	"ground_hitstun": 33 * kick_hitstun_mult,
	"air_hitstun" : 33 * kick_hitstun_mult,
	"ground_knockback_force" : 200 * kick_knockback_mult,
	"air_knockback_force" : 100 * kick_knockback_mult,
	"forward_force": 100 * kick_forward_mult,
	"damage": 30 * kick_damage_mult,
	"startup_animation" : "kick recovery",
	"active_animation" : "kick",
	"recovery_animation" : "kick recovery",
}

var crouch_kick_data = {
	"startup_frames" : 8.0 / kick_speed_mult,
	"active_frames" : 3,
	"recovery_frames" : 19.0 / kick_speed_mult,
	"blockstun_frames" : 16,
	"onBlock_FA" : -6,
	"ground_hitstun": 26 * kick_hitstun_mult,
	"air_hitstun" : 26 * kick_hitstun_mult,
	"ground_knockback_force" : 200 * kick_knockback_mult,
	"air_knockback_force" : 100 * kick_knockback_mult,
	"forward_force": 100 * kick_forward_mult,
	"damage": 15 * kick_damage_mult,
	"startup_animation" : "crouch kick recovery",
	"active_animation" : "crouch kick",
	"recovery_animation" : "crouch kick recovery",
}

var throw_data = {
	"startup_frames" : 15.0 / pose_speed_mult,
	"active_frames" : 3,
	"recovery_frames" : 30.0 / pose_speed_mult,
	"pose_frames" : 50,
	"ground_hitstun": 77 * pose_hitstun_mult, # This value needs to be pose_frames + 17, so that the attacker has 17 frames of frame advantage for posing first.
	"ground_knockback_force" : 100 * pose_knockback_mult,
	"forward_force": 0,
	"damage": 20 * pose_damage_mult,
	"startup_animation" : "jump startup",
	"active_animation" : "pose",
	"recovery_animation" : "pose recovery",
}

#Defines the player's walk speed, and jump speeds.
@export var SPEED = 20.0 * movement_speed_mult
@export var VERTICAL_JUMP_VELOCITY = -300.0 * jump_height_mult
@export var HORIZONTAL_JUMP_VELOCITY = 120 * jump_speed_mult

var startup_timer = 0.0
var startup_continuation = null

var recovery_timer = 0.0
var recovery_continuation = null

var pose_timer = 0.0

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
			crouch_input = "player_crouch"
			
			print("Player 1 Controls Enabled")
		2: 
			left_input = "player2_left"
			right_input = "player2_right"
			jump_input = "player2_jump"
			punch_input = "player2_punch"
			kick_input = "player2_kick"
			pose_input = "player2_throw"
			debug_hurt = "DEBUG_hurt_player2"
			crouch_input = "player2_crouch"
			
			print("Player 2 Controls Enabled")

func stop_all_timers():
	for child in get_children():
		if child is Timer:
			print(child)
			child.stop()

func apply_gravity(delta):
	
	if not is_on_floor():
		#We multiply gravity times 0.8 to make it slightly slower, so mess with this in tandem with the vertical jump velocity to change the player's jumping speed.
		velocity += (get_gravity() * 0.9) * delta

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
	hurtboxCollision = hurtbox.get_node("CollisionShape2D")
	
	if hurtboxCollision and hurtboxCollision.shape:
		hurtboxCollision.shape = hurtboxCollision.shape.duplicate()
	
	if collision and collision.shape:
		collision.shape = collision.shape.duplicate()
	
	
	
	if enemy == null:
		push_error("Enemy node '%s' not found!" % enemy_name)
	
	set_controls()
	disable_hitboxes()

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
	
	if disabled: direction = 0
	#This handles checking for the dash input, completely outside of the defined states below.
	check_for_dash()
	
	handle_states(direction, delta)

func reset_scale():
	
	hurtboxCollision.shape.size = Vector2(hurtboxCollision.shape.size.x, 50.0)
	hurtboxCollision.position.y = 4
	
	collision.shape.size = Vector2(collision.shape.size.x, 50.0)
	collision.position.y = 4
	
	animation_player.scale.y = 0.3
	animation_player.position.y = 4.5
	
	PantsLayer.scale.y = 0.3
	PantsLayer.position.y = 4.5
	
	ShirtLayer.scale.y = 0.3
	ShirtLayer.position.y = 4.5

func crouch_scale():
	hurtboxCollision.shape.size = Vector2(hurtboxCollision.shape.size.x, 29.0)
	hurtboxCollision.position.y = 14.5
	
	collision.shape.size = Vector2(collision.shape.size.x, 29.0)
	collision.position.y = 14.5
	
	animation_player.scale.y = 0.177
	animation_player.position.y = 14.61
	
	PantsLayer.scale.y = 0.177
	PantsLayer.position.y = 14.61
	
	ShirtLayer.scale.y = 0.177
	ShirtLayer.position.y = 14.61

func handle_states(direction, delta):
	if direction == 0: 
		block_legal = false
		crouch_block_legal = false
	
		#To add a new state, just add a new match case for that specific state, and similarly include the animation to be played and a call for that state's function. 
	match state:
		
		CharacterState.IDLE:
			animation_player.play("idle")
			PantsLayer.play("idle")
			ShirtLayer.play("idle")
			
			#Coming from the temporary solution of manipulating the animation player to simulate crouching...
			reset_scale()
			
			change_color(Color(Color.WHITE, 1.0))
			idle_state(direction)
			
		CharacterState.WALK:
			reset_scale()
			crouch_block_legal = false
			
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
			
			if (direction == facing_direction * -1): 
				block_legal = true
			else: 
				block_legal = false
			
			walk_state(direction)
		
		CharacterState.JUMP:
			animation_player.play("jump")
			PantsLayer.play("jump")
			ShirtLayer.play("jump")
			jump_state(direction, delta)
		
		CharacterState.DASH:
			
			change_color(Color(Color.LIGHT_YELLOW, 1.0))
			
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
			
			if (direction == facing_direction * -1): block_legal = true
			
			dash_state(delta)
		
		CharacterState.STARTUP:
			change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			startup_state(delta)
		
		CharacterState.PUNCH:
			reset_scale()
			
			change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			animation_player.play(punch_data["active_animation"])
			PantsLayer.play(punch_data["active_animation"])
			ShirtLayer.play(punch_data["active_animation"])
			punch_state(delta)
		
		CharacterState.CPUNCH:
			#crouch_scale()
			reset_scale()
			hurtboxCollision.shape.size = Vector2(hurtboxCollision.shape.size.x, 29.0)
			hurtboxCollision.position.y = 14.5
			
			collision.shape.size = Vector2(collision.shape.size.x, 29.0)
			collision.position.y = 14.5
			
			change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			
			animation_player.play(crouch_punch_data["active_animation"])
			PantsLayer.play(crouch_punch_data["active_animation"])
			ShirtLayer.play(crouch_punch_data["active_animation"])
			
			c_punch_state(delta)
		
		CharacterState.KICK:
			reset_scale()
			
			change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			animation_player.play(kick_data["active_animation"])
			PantsLayer.play(kick_data["active_animation"])
			ShirtLayer.play(kick_data["active_animation"])
			animation_player.position.x = 18
			ShirtLayer.position.x = 18
			PantsLayer.position.x = 18
			
			kick_state(delta)
		
		CharacterState.CKICK:
			reset_scale()
			
			change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			
			animation_player.play(crouch_kick_data["active_animation"])
			PantsLayer.play(crouch_kick_data["active_animation"])
			ShirtLayer.play(crouch_kick_data["active_animation"])
			animation_player.position.x = 8
			ShirtLayer.position.x = 8
			PantsLayer.position.x = 8
			
			c_kick_state(delta)
		
		CharacterState.RECOVERY:
			#change_color(Color(Color.WHITE, 1.0))
			block_legal = false
			crouch_block_legal = false
			recovery_state(delta)
		
		CharacterState.HURT:
			reset_scale()
			
			block_legal = false
			crouch_block_legal = false
			disable_hitboxes()
			change_color(Color(Color.PALE_VIOLET_RED, 1.0))
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, 25)
			
			animation_player.position.x = 4
			ShirtLayer.position.x = 4
			PantsLayer.position.x = 4
		
		CharacterState.BLOCK:
			animation_player.play("block")
			PantsLayer.play("block")
			ShirtLayer.play("block")
			
			change_color(Color(Color.ROYAL_BLUE, 1.0))
			
			disable_hitboxes()
			block_state(delta)
		
		CharacterState.POSE_STARTUP:
			pose_startup_state(delta)
		
		CharacterState.POSE:
			animation_player.play("pose")
			PantsLayer.play("pose")
			ShirtLayer.play("pose")
			disable_hitboxes()
			pose_state(delta)
		
		CharacterState.DEAD:
			reset_scale()
			
			animation_player.play("dead")
			change_color(Color(Color.DIM_GRAY, 1.0))
			PantsLayer.play("dead")
			ShirtLayer.play("dead")
			velocity.x = move_toward(velocity.x, 0, 25)
		
		CharacterState.CROUCH:
			reset_scale()
			
			if (direction == facing_direction * -1): 
				crouch_block_legal = true
			else: 
				crouch_block_legal = false
			
			#For now, we're gonna set it to idle and manipulate the scale of the animation player. Not a permanent solution. Don't forget to come back and fix this.
			animation_player.play("crouch punch startup")
			PantsLayer.play("crouch punch startup")
			ShirtLayer.play("crouch punch startup")
			
			#crouch_scale()
			hurtboxCollision.shape.size = Vector2(hurtboxCollision.shape.size.x, 29.0)
			hurtboxCollision.position.y = 14.5
			
			collision.shape.size = Vector2(collision.shape.size.x, 29.0)
			collision.position.y = 14.5
			
			change_color(Color(Color.WHITE, 1.0))
			crouch_state(direction)
		
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
			if crouch_input and Input.is_action_pressed(crouch_input):
				change_state(CharacterState.CROUCH)
			
			check_for_attack()
			check_for_pose()
			disable_hitboxes()
			
			cancellable = false
			
			velocity.x = move_toward(velocity.x, 0, 20)

func walk_state(direction):
	animation_player.position.x = 4
	ShirtLayer.position.x = 4
	PantsLayer.position.x = 4
	
	if direction == 0:
		change_state(CharacterState.IDLE)
	elif Input.is_action_pressed(jump_input) and is_on_floor():
		start_action(4, func(): start_jump(direction), "jump startup")
	elif Input.is_action_pressed(crouch_input) and is_on_floor():
		change_state(CharacterState.CROUCH)
	else:
		velocity.x = direction * SPEED
		check_for_attack()
		check_for_pose()

func crouch_state(direction):
	if Input.is_action_just_released(crouch_input):
		print("You just released the crouch button!")
		change_state(CharacterState.IDLE)
		
	if disabled: return
	
	disable_hitboxes()
	check_for_attack()
	cancellable = false
	velocity.x = move_toward(velocity.x, 0, 20)
	
	#Will need to investigate to figure out what exactly can be done from a crouch, but from the top of our head, check for attacks. Check for jump. 
	# CONSIDER: Should they be able to throw from crouching?
	# CONSIDER: How will we handle blocking while crouching?

func start_jump(direction):
	left_ground_check = false
		
	velocity.y = VERTICAL_JUMP_VELOCITY
	
	if direction:
		velocity.x = direction * HORIZONTAL_JUMP_VELOCITY
	else:
		velocity.x = 0
	
	change_state(CharacterState.JUMP)
	SfxManager.playJump()

func jump_state(direction, delta):
	if not left_ground_check and not is_on_floor():
		left_ground_check = true
	
	check_for_attack()
	
	if player_type == 1: print("jump state")
	animation_player.position.x = 4
	ShirtLayer.position.x = 4
	PantsLayer.position.x = 4
	
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
	
	if is_on_floor() and Input.is_action_pressed(crouch_input):
		change_state(CharacterState.CROUCH)
	
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
	SfxManager.playPunchMiss()
	SfxManager.playPunchVoice()

func punch_state(delta):
	if (is_on_floor()): velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		start_recovery(punch_data["recovery_frames"], punch_data["recovery_animation"])

func start_c_punch():
	if (state != CharacterState.STARTUP): return
	
	attack_timer = punch_data["active_frames"] * FRAME
	l_punch_hitbox.enable()
	cancellable = true
	
	change_state(CharacterState.CPUNCH)
	SfxManager.playPunchMiss()
	SfxManager.playPunchVoice()

func c_punch_state(delta):
	if (is_on_floor()): velocity.x = move_toward(velocity.x, 0, crouch_punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		start_recovery(crouch_punch_data["recovery_frames"], crouch_punch_data["recovery_animation"])

#This is where the code goes for the moment the kick is active. LATER ON, add the sound effect in this function.
func start_kick():
	if (state == CharacterState.STARTUP): 
		print("Starting kick!")
		attack_timer = kick_data["active_frames"] * FRAME
		velocity.x = kick_data["forward_force"] * facing_direction
		kick_hitbox.enable()
		
		cancellable = false
		
		change_state(CharacterState.KICK)
		SfxManager.playKickMiss()
		SfxManager.playKickVoice()

func kick_state(delta):
	velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		start_recovery(kick_data["recovery_frames"], kick_data["recovery_animation"])

func start_c_kick():
	if (state != CharacterState.STARTUP): return
	
	print("Starting crouch kick!")
	attack_timer = crouch_kick_data["active_frames"] * FRAME
	velocity.x = crouch_kick_data["forward_force"] * facing_direction
	l_kick_hitbox.enable()
		
	cancellable = false
		
	change_state(CharacterState.CKICK)
	SfxManager.playKickMiss()
	SfxManager.playKickVoice()

func c_kick_state(delta):
	#velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	
	if attack_timer > 0:
		attack_timer -= delta
	else:
		if player_type == 1: print("end kick state")
		
		animation_player.position.x = 4
		ShirtLayer.position.x = 4
		PantsLayer.position.x = 4
		
		start_recovery(crouch_kick_data["recovery_frames"], crouch_kick_data["recovery_animation"])

#In block_state(), slow down at regular speed, decrement block_timer by delta until it's 0 and change_state(CharacterState.IDLE)
func block_state(delta):
	velocity.x = move_toward(velocity.x, 0, 20)
	
	if block_timer > 0:
		block_timer -= delta
	else:
		if Input.is_action_pressed(crouch_input) and is_on_floor():
			change_state(CharacterState.CROUCH)
		else:
			change_state(CharacterState.IDLE)

func start_recovery(frames, animation):
	#if (state != CharacterState.PUNCH) and (state != CharacterState.KICK): return
	if dead: return
	change_state(CharacterState.RECOVERY)
	
	animation_player.play(animation)
	PantsLayer.play(animation)
	ShirtLayer.play(animation)
	recovery_timer = frames * FRAME
	recovery_continuation = func(): 
		if state != CharacterState.STARTUP and state != CharacterState.HURT: 
			if (Input.is_action_pressed(crouch_input)):
				change_state(CharacterState.CROUCH)
			else:
				change_state(CharacterState.IDLE)

func recovery_state(delta):
	if (is_on_floor()): velocity.x = move_toward(velocity.x, 0, punch_deceleration)
	if cancellable: check_for_attack()
	disable_hitboxes()
	
	if recovery_timer > 0:
		recovery_timer -= delta
	else:
		
		if recovery_continuation != null:
			recovery_continuation.call()
			animation_player.position.x = 4
			ShirtLayer.position.x = 4
			PantsLayer.position.x = 4
			recovery_continuation = null

func get_hit_with(attack_data):
	SfxManager.playHit()
	change_state(CharacterState.HURT)
	
	animation_player.play("hurt")
	PantsLayer.play("hurt")
	ShirtLayer.play("hurt")
	velocity.y = 0
	velocity.x = 0
	reset_scale()
	
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
	
	startup_timer = frames * FRAME
	startup_continuation = continuation

func startup_state(delta):
	#Noting this to remember later. Freezing the player's horizontal velocity during startup might be a problem. 
	if is_on_floor(): velocity.x = 0
	
	if startup_timer > 0:
		startup_timer -= delta
	else:
		if player_type == 0: print("Startup timer ended!")
		if startup_continuation != null:
			startup_continuation.call()
			startup_continuation = null

#When you press throw, enter POSE_STARTUP, then, after startup_frames, trigger POSE hitbox
func start_pose():
	change_state(CharacterState.POSE_STARTUP)
	
	animation_player.play(throw_data["startup_animation"])
	PantsLayer.play(throw_data["startup_animation"])
	ShirtLayer.play(throw_data["startup_animation"])
	
	pose_timer = throw_data["startup_frames"] * FRAME

func pose_startup_state(delta):
	change_color(Color(0.7, 0.1, 0.37))
	velocity.x = 0
	
	animation_player.position.x = 4
	ShirtLayer.position.x = 4
	PantsLayer.position.x = 4
	
	if pose_timer > 0:
		pose_timer -= delta
	else:
		throw_hitbox.enable()
	
#In pose(), enter POSE state. If the parameter is null, start_recovery() with POSE animation for recovery_frames. If it's not null, call target's get_hit_with() with the data of my throw, and then start_recovery() with POSE animation for pose_frames 
func pose(target):
	change_state(CharacterState.POSE)
	change_color(Color(1.0, 0.71, 0.76))
	
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
	if player_type == 1: print(str(player_type) + ": Character State Updated: " + CharacterState.keys()[state])

func check_for_attack():
	if disabled == true: 
		return
	
	if Input.is_action_pressed(punch_input):
		if Input.is_action_pressed(crouch_input) and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			start_action(crouch_punch_data["startup_frames"], func(): 
				if state == CharacterState.STARTUP:
					start_c_punch()
				, crouch_punch_data["startup_animation"])
		elif not (Input.is_action_pressed(crouch_input)) and state != CharacterState.CROUCH:
			stop_all_timers()
			start_action(punch_data["startup_frames"], func(): 
				if state == CharacterState.STARTUP:
					start_punch()
				, punch_data["startup_animation"])
	
	if Input.is_action_pressed(kick_input):
		if Input.is_action_pressed(crouch_input) and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			
			#animation_player.position.x = 18
			#ShirtLayer.position.x = 18
			#PantsLayer.position.x = 18
			#crouch_scale()
			
			start_action(crouch_kick_data["startup_frames"], func():
				if state==CharacterState.STARTUP:
					start_c_kick()
				, crouch_kick_data["startup_animation"])
		elif not (Input.is_action_pressed(crouch_input)) and state != CharacterState.CROUCH:
			print("You aren't pressing crouch or in the crouch state!")
			
			stop_all_timers()
			animation_player.position.x = 18
			ShirtLayer.position.x = 18
			PantsLayer.position.x = 18
			reset_scale()
			
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
	if not disabled and Input.is_action_pressed(jump_input):
		start_action(4, func(): start_jump(0), "jump startup")

func attack_hit(target):
	
	if target.has_method("get_hit_with"):
		match state:
			CharacterState.PUNCH:
				print("Hitting " + str(target) + " with the almighty punch!")
				SfxManager.playPunchHit()
				target.get_hit_with(punch_data)
				
			
			CharacterState.KICK:
				print("Hitting " + str(target) + " with the almighty kick!")
				SfxManager.playKickHit()
				target.get_hit_with(kick_data)
			
			CharacterState.CPUNCH:
				print("Hitting " + str(target) + " with the almighty CROUCH punch!")
				SfxManager.playPunchHit()
				target.get_hit_with(crouch_punch_data)
			
			CharacterState.CKICK:
				print("Hitting " + str(target) + " with the almighty CROUCH kick!")
				SfxManager.playKickHit()
				target.get_hit_with(crouch_kick_data)

func reduce_health(damage):
	health -= damage
	print(str(player_type) + ": Taken damage.")
	
	#This is where the code would go for playing a hurt sound effect -- IF I HAD ONE!!
	update_healthbar()
	
	if health <= 0:
		disable_hitboxes()
		stop_all_timers()
		
		change_state(CharacterState.DEAD)
		#rotation_degrees = 90
		
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
		
		elif child is CrouchHitbox:
			child.disable()

func face_your_opponent():
	if not (state == CharacterState.IDLE or state == CharacterState.WALK): return
	 
	#if player_type == 1: print(vertical_distance)
	enemy_direction = sign(enemy.global_position.x - global_position.x)
	horizontal_distance = abs(enemy.global_position.x - global_position.x)
	vertical_distance = enemy.global_position.y - global_position.y
	
	if (horizontal_distance < 26) and (vertical_distance > 19) and is_on_floor():
		print("I'm standing on top of him.") 
		velocity.y = -50
		velocity.x = facing_direction * -1 * 140
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
				SfxManager.playBlock()
				
				# Apply slowdown penalty for punching a blocking enemy
				if not hit_block_slowdown and player_type != 0:
					hit_block_slowdown = true
					original_speed = SPEED
					SPEED = SPEED * 0.3
					disabled = true
					
					await get_tree().create_timer(0.1).timeout
					
					SPEED = original_speed
					disabled = false
					hit_block_slowdown = false
				
				await get_tree().create_timer(attack_timer).timeout
				velocity.x = -1 * (facing_direction) * 150 + 50
				start_recovery((punch_data["recovery_frames"] - punch_data["onBlock_FA"]), punch_data["recovery_animation"])
			
			CharacterState.CPUNCH:
				print("Target, " + str(target) + " has blocked my CROUCHING punch!")
				target.block_attack(crouch_punch_data)
				SfxManager.playBlock()
				
				# Knockback for blocked crouch punch
				velocity.x = -1 * (facing_direction) * 200
				
				# Apply slowdown penalty for crouching punch on block
				if not hit_block_slowdown and player_type != 0:
					hit_block_slowdown = true
					original_speed = SPEED
					SPEED = SPEED * 0.3
					disabled = true
					
					await get_tree().create_timer(0.1).timeout
					
					SPEED = original_speed
					disabled = false
					hit_block_slowdown = false
				
				await get_tree().create_timer(attack_timer).timeout
				start_recovery((crouch_punch_data["recovery_frames"] - crouch_punch_data["onBlock_FA"]), crouch_punch_data["recovery_animation"])
			
			CharacterState.KICK:
				print("Target, " + str(target) + " has blocked my kick!")
				target.block_attack(kick_data)
				SfxManager.playBlock()
				await get_tree().create_timer(attack_timer).timeout
				start_recovery((attack_timer + kick_data["recovery_frames"] - kick_data["onBlock_FA"]), kick_data["recovery_animation"])
			
			CharacterState.CKICK:
				print("Target, " + str(target) + " has blocked my CROUCHING kick!")
				target.block_attack(crouch_kick_data)
				SfxManager.playBlock()
				
				# Knockback for blocked crouch kick
				velocity.x = -1 * (facing_direction) * 250
				
				await get_tree().create_timer(attack_timer).timeout
				start_recovery((attack_timer + crouch_kick_data["recovery_frames"] -  crouch_kick_data["onBlock_FA"]), crouch_kick_data["recovery_animation"])
#When we're the ones blocking an attack, set state to BLOCK, take negative x velocity of half of the attack's knockback, set block_timer to the given attack's blockstun frames
func block_attack(attack_data):
	change_state(CharacterState.BLOCK)
	velocity.x = -1 * (facing_direction) * attack_data["ground_knockback_force"] / 2
	block_timer = attack_data["blockstun_frames"] * FRAME

func update_healthbar():
	if (healthbar == null): return
	#This is where we'd call on the UI to update the reduced health -- IF I HAD ONE!! ---update from later Tomie: we do have one. it's just funny to leave it here now.
	healthbar.health = health
	#health_UI.text = str(health)
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

func scale_stats():
	
	#The stats of the current implementation of the clothing stats system were set with it in mind that they'd be *added* rather than set directly to the clothing.
	#This means that, on the clothing items themselves, they need a 0 on the stats they don't affect, and the specified positive or negative decimal values from the spreadsheet for the stats they *do* affect.
	#Here, we have to then just add those values to the given mults starting off at 1. If the clothing has a 0 and it's not supposed to affect that clothing, it'll just add 0. If two clothing items add to the same item, they'll stack, as intended. If they add and subtract the same stat, then the stat will keep the difference, as intended. 
	
	var pants = get_child(3).current_wearable
	var shirt = get_child(4).current_wearable
	
	#movement_speed_mult += pants.get_walk_speed_change() + shirt.get_walk_speed_change()
	#SPEED *= movement_speed_mult
	dash_speed_mult += pants.get_dash_speed_change()+ shirt.get_dash_speed_change()
	DASH_SPEED *= dash_speed_mult
	DASH_TIME /= dash_speed_mult
	
	#dash_available +=
	jump_height_mult += pants.get_jump_height_change()+ shirt.get_jump_height_change()
	#jump_speed_mult +=
	
	# So, fun fact for the below stat mults -- in the current implementation of the clothing stats system, the shirts will affect the punch stats, and the pants will affect the kick stats. So, the given mults only need to check for that item of clothing!
	
	punch_speed_mult += shirt.get_attack_speed_change()
	punch_data["startup_frames"] /= punch_speed_mult
	punch_data["recovery_frames"] /= punch_speed_mult
	crouch_punch_data["startup_frames"] /= punch_speed_mult
	crouch_punch_data["recovery_frames"] /= punch_speed_mult

	punch_hitstun_mult += shirt.get_hitstun_length_change()
	punch_data["ground_hitstun"] /= punch_hitstun_mult
	punch_data["air_hitstun"] /= punch_hitstun_mult
	crouch_punch_data["ground_hitstun"] /= punch_hitstun_mult
	crouch_punch_data["air_hitstun"] /= punch_hitstun_mult
	
	punch_knockback_mult += shirt.get_knockback_change()
	punch_data["ground_knockback_force"] *= punch_knockback_mult
	punch_data["air_knockback_force"] *= punch_knockback_mult
	crouch_punch_data["ground_knockback_force"] *= punch_knockback_mult
	crouch_punch_data["air_knockback_force"] *= punch_knockback_mult
	
	punch_damage_mult += shirt.get_attack_damage_change()
	punch_data["damage"] = (punch_data["damage"] * temperature) * punch_damage_mult
	crouch_punch_data["damage"] = (crouch_punch_data["damage"] * temperature) * punch_damage_mult 
	
	kick_speed_mult += pants.get_attack_speed_change()
	kick_data["startup_frames"] /= kick_speed_mult
	kick_data["recovery_frames"] /= kick_speed_mult
	crouch_kick_data["startup_frames"] /= kick_speed_mult
	crouch_kick_data["recovery_frames"] /= kick_speed_mult
	
	kick_hitstun_mult += pants.get_hitstun_length_change()
	kick_data["ground_hitstun"] /= kick_hitstun_mult
	kick_data["air_hitstun"] /= kick_hitstun_mult
	crouch_kick_data["ground_hitstun"] /= kick_hitstun_mult
	crouch_kick_data["air_hitstun"] /= kick_hitstun_mult
	
	kick_knockback_mult += pants.get_knockback_change()
	kick_data["ground_knockback_force"] *= kick_knockback_mult
	kick_data["air_knockback_force"] *= kick_knockback_mult
	crouch_kick_data["ground_knockback_force"] *= kick_knockback_mult
	crouch_kick_data["air_knockback_force"] *= kick_knockback_mult
	
	kick_damage_mult += pants.get_attack_damage_change()
	kick_data["damage"] = (kick_data["damage"] * temperature) * kick_damage_mult 
	crouch_kick_data["damage"] = (crouch_kick_data["damage"] * temperature) *  kick_damage_mult 
	
	pose_speed_mult += shirt.get_pose_speed_change() + pants.get_pose_speed_change()
	throw_data["startup_frames"] = 10 / pose_speed_mult
	throw_data["recovery_frames"] = 30 / pose_speed_mult
	
	pose_hitstun_mult += shirt.get_pose_hitstun_change() + pants.get_pose_hitstun_change()
	throw_data["ground_hitstun"] = 77 * pose_hitstun_mult
	
	pose_knockback_mult += shirt.get_pose_knockback_change() + pants.get_pose_knockback_change()
	throw_data["ground_knockback_force"] = 100 * pose_knockback_mult
	
	pose_damage_mult += shirt.get_pose_damage_change() + pants.get_pose_damage_change()
	throw_data["damage"] = 20 * pose_damage_mult
	
	health_mult += shirt.get_health_change() + pants.get_health_change()
	health = (200 * temperature) * health_mult
	starting_health = health

func report_dead():
	pass

func change_color(color):
	self.modulate = color

func revive():
	dead = false
	state = CharacterState.IDLE
	health = starting_health
	disabled = true
	if healthbar != null:
		healthbar.init_health(health)
