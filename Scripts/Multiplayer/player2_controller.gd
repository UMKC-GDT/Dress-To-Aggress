extends BaseCharacterController

signal two_died

var pid

#These are all booleans that are used to override functions way below and replace the original Input. checks. Basically, we're giving the CPU buttons! :D
var pressing_left = false
var pressing_right = false
var pressing_jump = false
var punch_pressed = false
var kick_pressed = false
var pose_pressed = false
var crouch_pressed = false
var block_pressed = false

func release_inputs():
	pressing_left = false
	pressing_right = false
	pressing_jump = false
	punch_pressed = false
	kick_pressed = false
	pose_pressed = false
	crouch_pressed = false

#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	player_type = 2 # 0 = CPU, 1 = Player 1, 2 = Player 2
	enemy_name = "Player"
	healthbar = $"/root/Test Level/CanvasLayer/Healthbar2"
	super.scale_stats()
	healthbar.init_health(health)
	super._ready()

#Overloads the player's handle_input for the CPU. by checking the booleans and calling other necessary functions to set its eyes.
func handle_input(delta):
	horizontal_distance = abs(position.x - enemy.position.x)
	vertical_distance = enemy.global_position.y - global_position.y
	
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
	
	handle_states(direction, delta)

func crouch():
	crouch_pressed = true

func uncrouch():
	crouch_pressed = false

func punch():
	punch_pressed = true
	await get_tree().create_timer(0.02).timeout
	punch_pressed = false
	uncrouch()

func kick():
	kick_pressed = true
	await get_tree().create_timer(0.03).timeout
	kick_pressed = false
	uncrouch()

func jump():
	pressing_jump = true
	await get_tree().create_timer(0.1).timeout
	pressing_jump = false

func use_pose():
	pose_pressed = true
	await get_tree().create_timer(0.2).timeout
	pose_pressed = false

#Everything from here down is functions from the parent class, overridden so that the CPU controller isn't checking for player inputs. Don't peek behind the curtain -- the void stares back.
func walk_state(direction):
	if direction == 0:
		change_state(CharacterState.IDLE)
	elif pressing_jump and is_on_floor():
		start_action(4, func(): start_jump(direction), "jump startup")
	elif crouch_pressed and is_on_floor():
		change_state(CharacterState.CROUCH)
	else:
		velocity.x = direction * SPEED
		check_for_attack()
		check_for_pose()

func idle_state(direction):
	if is_on_floor():
		dashes_left = 1
		
		if direction: 
			change_state(CharacterState.WALK)
		else:
				
			if not disabled:
				check_for_jump()
			if crouch_pressed:
				change_state(CharacterState.CROUCH)
			
			check_for_attack()
			check_for_pose()
			disable_hitboxes()
			
			cancellable = false
			
			velocity.x = move_toward(velocity.x, 0, 20)

func crouch_state(direction):
	if not crouch_pressed:
		print("CPU just released the crouch button!")
		change_state(CharacterState.IDLE)
		
	if disabled: return
	
	disable_hitboxes()
	check_for_attack()
	cancellable = false
	velocity.x = move_toward(velocity.x, 0, 20)

func block_state(delta):
	velocity.x = move_toward(velocity.x, 0, 20)
	
	if block_timer > 0:
		block_timer -= delta
	else:
		if crouch_pressed and is_on_floor():
			change_state(CharacterState.CROUCH)
		else:
			change_state(CharacterState.IDLE)

func check_for_attack():
	if disabled == true: 
		return
	
	if punch_pressed:
		if crouch_pressed and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			start_action(crouch_punch_data["startup_frames"], func(): 
				if state == CharacterState.STARTUP:
					start_c_punch()
				, crouch_punch_data["startup_animation"])
		elif not (crouch_pressed) and state != CharacterState.CROUCH:
			stop_all_timers()
			start_action(punch_data["startup_frames"], func(): 
				if state == CharacterState.STARTUP:
					start_punch()
				, punch_data["startup_animation"])
	
	if kick_pressed:
		if crouch_pressed and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			
			animation_player.position.x = 18
			ShirtLayer.position.x = 18
			PantsLayer.position.x = 18
			crouch_scale()
			
			start_action(crouch_kick_data["startup_frames"], func():
				if state==CharacterState.STARTUP:
					start_c_kick()
				, crouch_kick_data["startup_animation"])
		elif not (crouch_pressed) and state != CharacterState.CROUCH:
			print("CPU isn't pressing crouch or in the crouch state!")
			
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
	
	if pose_pressed:
		stop_all_timers()
		start_pose()

func check_for_jump():
	if pressing_jump:
		start_action(4, func(): start_jump(0), "jump startup")

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
			if (crouch_pressed):
				change_state(CharacterState.CROUCH)
			else:
				change_state(CharacterState.IDLE)

func send_input(input: Dictionary): 
	for l in input:
		var vx: int = int(input.get("x", 0))
		if vx < 0:
			pressing_left = true
			pressing_right = false
		elif vx > 0: 
			pressing_right = true
			pressing_left = false
		else:
			pressing_left = false
			pressing_right = false
		match l:
			"player_punch":
				if(!input[l]): continue
				punch()
			"player_kick":
				if(!input[l]): continue
				kick()
			"player_jump":
				if(!input[l]): continue
				jump()
			"player_throw":
				if(!input[l]): continue
			"player_crouch":
				if(!input[l]): 
					uncrouch()
					continue 
				crouch()
func report_dead():
	SfxManager.playDeath()
	two_died.emit()
