extends BaseCharacterController

signal cpu_died

#These are all booleans that are used to override functions way below and replace the original Input. checks. Basically, we're giving the CPU buttons! :D
var pressing_left = false
var pressing_right = false
var pressing_jump = false
var punch_pressed = false
var kick_pressed = false
var pose_pressed = false

#enum Enemy_Range { POSE, PUNCH, KICK, FAR}
#var range = Enemy_Range.POSE

#From here, we're defining the CPU's "eyes", like what the current state is, what their last state was, if they're attacking, what their last attack was, etc etc
var enemy_state = CharacterState.IDLE
var last_enemy_state = CharacterState.IDLE

#These two, in particular, are useful for checking before blocking
var enemy_attacking = true
var current_enemy_attack = CharacterState.IDLE

#These are useful for checking when we can punish. If the player's just attacked, and they're in attack range, and they're in recovery, then kick, for example.
var enemy_just_attacked = false
var last_enemy_attack = CharacterState.IDLE 

#Could be useful for checking if the enemy's blocking to break their block by POSE
var enemy_blocking = false

#This one defines the enemy CPU's "eyes" for knowing if the player's approaching, retreating, or standing in place. 1 for approaching (getting closer), -1 for retreating, 0 for idle.
var enemy_approaching

#Rather than an enum, THIS is what you check horizontal distance against to react based on the player's distance. If their horizontal distance is less than kick range, they're in kick range, for example. 
var pose_range = 31
var punch_range = 34
var kick_range = 46

var kick_time = 0.30
var punch_time = 0.15

var roll = 0

func release_inputs():
	pressing_left = false
	pressing_right = false
	pressing_jump = false
	punch_pressed = false
	kick_pressed = false
	pose_pressed = false

#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	player_type = 0
	enemy_name = "Player"
	super._ready()

#Overloads the player's handle_input for the CPU. by checking the booleans and calling other necessary functions to set its eyes.
func handle_input(delta):
	horizontal_distance = abs(position.x - enemy.position.x)
	vertical_distance = enemy.global_position.y - global_position.y
	
	if Input.is_action_pressed("DEBUG_hurt_player"):
		dash_towards()
	
	if not disabled:
		if pressing_left:
			direction = -1
		elif pressing_right:
			direction = 1
		elif (state != CharacterState.DASH) and (direction == 1 and not pressing_right) or (direction == -1 and not pressing_left):
			direction = 0
			block_legal = false
	else:
		direction = 0
	
	#find_range()
	find_state()
	find_aggression()
	check_enemy_attack()
	handle_states(direction, delta)
	
	#this is where the fun begins
	run_ai()

#The fun. This is where our AI code can go, and, to whomever's working on the AI code, work your magic here. All of the code below can be edited and extended to however deep you want, based on the given eyes.
func run_ai():
	
	if disabled: return
	
	#Example on how to make the CPU approach to a range. The + and - 2 are necessary because, if it's exact, it starts jittering back and forth. Give it a little leeway.
	if horizontal_distance > kick_range + 2 or enemy_approaching == 0:
		if randf() < 0.2: approach()
	elif horizontal_distance < kick_range - 2:
		if randf() < 0.8: retreat()
	else:
		release_inputs()
	
	#Example on how to make the CPU anti air. This and the below functions are reactionary, so you might want to link them to a random number to make it only have a CHANCE at reacting and defending. Higher chance == harder CPU.
	if enemy_state == CharacterState.JUMP: 
		if vertical_distance < 30:
			if horizontal_distance < kick_range + 3 and horizontal_distance >= kick_range and enemy_approaching == 1:
				if randf() < 0.5:
					kick()
	
	#if horizontal_distance < kick_range:
	#	if get_random_number() < 1:
	#		punch()
	#	elif get_random_number() < 2:
	#		kick()
	if horizontal_distance < kick_range:
		if randf() < 0.35:
			punch()
		elif randf() < 0.35:
			kick()
	
	#Example on how to make the CPU pose at pose range.
	if horizontal_distance <= pose_range:
		if randf() < 0.3:
			if is_on_floor(): use_pose()
	
	#Example on how to make it block. The "***_time" variables tell the CPU to hold block for that long to properly block the attack. Make this chance based, or we'll have a perfect CPU that blocks every attack.
	if (Input.is_action_just_pressed(enemy.punch_input) and horizontal_distance <= punch_range):
		if randf() < 0.6:
			block(punch_time)
		elif randf() < 0.6:
			dash_away()
	
	elif (Input.is_action_just_pressed(enemy.kick_input) and horizontal_distance <= kick_range):
		if randf() < 0.6:
			block(kick_time) 
		elif randf() < 0.6:
			dash_away()
	
	#Example on punishing after blocking a kick. This can be easily copied to make it punish punches.
	if (enemy_just_attacked and enemy.state == CharacterState.RECOVERY and horizontal_distance <= kick_range):
		if randf() < 0.5:
			kick()
	if (enemy_just_attacked and enemy.state == CharacterState.RECOVERY and horizontal_distance <= punch_range):
		if randf() < 0.5:
			punch()
	if (enemy_blocking and enemy.state == CharacterState.WALK and horizontal_distance <= kick_range):
		if randf() < 0.4:
			approach()
			use_pose()


#This set of functions define the CPU's movement relative to the player. A little bit of underlying logic here, might not need to mess with it. Hopefully. Maybe.
func walk_closer():
	
	block_legal = false
	
	if facing_direction == 1:
		pressing_left = false
		pressing_right = true
	elif facing_direction == -1:
		pressing_right = false
		pressing_left = true

func walk_away():
	if state != CharacterState.RECOVERY: block_legal = true
	
	if facing_direction == 1:
		pressing_left = true
		pressing_right = false
	elif facing_direction == -1:
		pressing_right = true
		pressing_left = false

func jump_forward():
	pressing_left = false
	pressing_right = false
	walk_closer()
	pressing_jump = true
	await get_tree().create_timer(0.1).timeout
	pressing_jump = false
	pressing_left = false
	pressing_right = false

func jump_away():
	walk_away()
	pressing_jump = true
	await get_tree().create_timer(0.2).timeout
	pressing_jump = false
	pressing_left = false
	pressing_right = false

func dash_away():
	
	if (dash_available == false): return
	if disabled: return
	
	if state == CharacterState.IDLE or state == CharacterState.WALK or state == CharacterState.JUMP:
		if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN): #check that dash is off cooldown
			if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
				start_dash(facing_direction * -1)
		dash_direction = facing_direction * -1

func dash_towards():
	
	if (dash_available == false): return
	if disabled: return
	
	if state == CharacterState.IDLE or state == CharacterState.WALK or state == CharacterState.JUMP:
		if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN): #check that dash is off cooldown
			if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
				start_dash(facing_direction)
		dash_direction = facing_direction


func approach():
	roll = get_random_number()
	
	if (is_on_floor()):
		if roll <= 80:
			walk_closer()
		elif roll <= 95:
			dash_towards()
		else:
			print(roll)
			if randf() < 0.35:
				jump_forward()

func retreat():
	roll = get_random_number()
	
	if (is_on_floor()):
		if roll <= 80:
			walk_away()
		elif roll <= 95:
			dash_away()
		else:
			print(roll)
			if randf() < 0.35:
				jump_away()

#These functions make the CPU "press buttons". It makes the corresponding boolean true for an instant, and then makes it false, similarly to how a player presses and releases a button. 
func block(time):
	if get_random_number() < 20:
		walk_away()
		await get_tree().create_timer(time).timeout
		pressing_left = false
		pressing_right = false

func punch():
	punch_pressed = true
	await get_tree().create_timer(0.2).timeout
	punch_pressed = false

func kick():
	kick_pressed = true
	await get_tree().create_timer(0.3).timeout
	kick_pressed = false

func jump():
	pressing_jump = true
	await get_tree().create_timer(0.1).timeout
	pressing_jump = false

func use_pose():
	pose_pressed = true
	await get_tree().create_timer(0.2).timeout
	pose_pressed = false

#I CAN SEE THE UNIVERSE
#Defines the logic for the CPU's eye variables, and reading that data of what the player's doing.
func find_state():
	if "state" in enemy:
		enemy_state = enemy.state
		last_enemy_state = enemy.last_state

func find_aggression():
	if (enemy.direction == enemy.facing_direction * -1):
		enemy_approaching = -1
	elif enemy.direction == enemy.facing_direction:
		enemy_approaching = 1
	elif enemy_state == CharacterState.IDLE:
		enemy_approaching = 0

#func set_range(new_range):
	#if dead: return
	#
	#range = new_range
	##print(str(player_type) + ": Enemy Range Updated: " + Enemy_Range.keys()[range])

func check_enemy_attack():
	if enemy_state == CharacterState.PUNCH or enemy_state == CharacterState.KICK or enemy_state == CharacterState.POSE:
		enemy_attacking = true
		current_enemy_attack = enemy_state
	elif last_enemy_state == CharacterState.PUNCH or last_enemy_state == CharacterState.KICK or last_enemy_state == CharacterState.POSE:
		enemy_just_attacked = true
		last_enemy_attack = last_enemy_state
	else:
		enemy_attacking = false
		current_enemy_attack = null
		
		enemy_just_attacked = false
		last_enemy_attack = null

func get_random_number():
	return randi() % 100 + 1

#Everything from here down is functions from the parent class, overridden so that the CPU controller isn't checking for player inputs. Don't peek behind the curtain -- the void stares back.
func walk_state(direction):
	if direction == 0:
		change_state(CharacterState.IDLE)
	elif pressing_jump and is_on_floor():
		start_action(4, func(): start_jump(direction), "jump startup")
	else:
		velocity.x = direction * SPEED
		check_for_attack()
		check_for_pose()

func check_for_attack():
	if disabled == true: 
		return
	
	if punch_pressed:
		stop_all_timers()
		start_action(punch_data["startup_frames"], func(): 
			if state == CharacterState.STARTUP:
				start_punch()
			, punch_data["startup_animation"])
	
	if kick_pressed:
		stop_all_timers()
		start_action(kick_data["startup_frames"], func(): 
			if state == CharacterState.STARTUP:
				start_kick()
			, kick_data["startup_animation"])

func check_for_pose():
	if disabled: return
	
	if pose_pressed:
		stop_all_timers()
		start_pose()

func check_for_jump():
	if pressing_jump:
		start_action(4, func(): start_jump(0), "jump startup")
		
func report_dead():
	cpu_died.emit()
