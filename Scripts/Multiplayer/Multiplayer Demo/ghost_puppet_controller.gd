extends BaseCharacterController
class_name GhostPuppetController

signal cpu_died

# ---- Wiring ----
@export var pid: int = 0
@export var nim_path: NodePath = NodePath("../NetworkInputManager")
@onready var nim: Node = get_node_or_null(nim_path)

func bind_to_manager(manager: Node) -> void:
	nim = manager
	_connect_nim()

func _connect_nim() -> void:
	if nim == null: return
	if nim.has_signal("server_move"):
		nim.server_move.connect(_on_server_move)
	if nim.has_signal("server_action"):
		nim.server_action.connect(_on_server_action)
	if nim.has_signal("server_rollback"):
		nim.server_rollback.connect(_on_server_rollback)

# ---- Input booleans (same as CPU) ----
var pressing_left: bool = false
var pressing_right: bool = false
var pressing_jump: bool = false
var punch_pressed: bool = false
var kick_pressed: bool = false
var pose_pressed: bool = false
var crouch_pressed: bool = false

# ---- Enemy “eyes” (kept for base behaviors; unchanged) ----
var enemy_state = CharacterState.IDLE
var last_enemy_state = CharacterState.IDLE
var enemy_attacking = true
var current_enemy_attack = CharacterState.IDLE
var enemy_just_attacked = false
var last_enemy_attack = CharacterState.IDLE
var enemy_blocking = false
var enemy_crouching = false
var enemy_approaching
var pose_range = 32
var punch_range = 36
var kick_range = 50
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
	crouch_pressed = false

# ---- Lifecycle ----
func _ready():
	player_type = 0
	enemy_name = "Player"
	super.scale_stats()
	super._ready()
	_connect_nim()
	if nim: nim.register_fighter(pid, self)  # << injects the correct bar

# ---- Network wiring (from NIM) ----
func _on_server_move(tick: int, pid_in: int, dx: int, dy: int) -> void:
	if pid_in != pid: return
	# Map per-tick dx to held booleans (CPU expects holds)
	if dx < 0:
		pressing_left = true
		pressing_right = false
	elif dx > 0:
		pressing_left = false
		pressing_right = true
	else:
		pressing_left = false
		pressing_right = false
	# (dy is ignored here; crouch is its own action in inputs)

func _on_server_action(tick: int, pid_in: int, action: String) -> void:
	if pid_in != pid: return
	match action:
		"punch":
			# Use the CPU’s press helper for exact timing/behavior
			punch()
		"kick":
			kick()
		"jump":
			jump()
		"throw":
			use_pose()
		"crouch":
			crouch_pressed = true
		_:
			pass

func _on_server_rollback(tick: int, pid_in: int, action: String) -> void:
	if pid_in != pid: return
	# Only one we treat as “hold” is crouch.
	if action == "crouch":
		crouch_pressed = false

# ---- Core control (unchanged CPU behaviors, minus AI driving) ----
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
		elif (state != CharacterState.DASH) and ((direction == 1 and not pressing_right) or (direction == -1 and not pressing_left)):
			direction = 0
			block_legal = false
	else:
		direction = 0

	find_state()
	find_aggression()
	find_crouch()
	check_enemy_attack()
	handle_states(direction, delta)

	# NOTE: no AI here (Easy/Normal/Hard); NIM drives inputs.

# ---- The rest is copied CPU behavior (unchanged) ----
func run_normal_ai(): pass
func run_easy_ai(): pass
func run_hard_ai(): pass

func walk_closer():
	block_legal = false
	uncrouch()
	if facing_direction == 1:
		pressing_left = false
		pressing_right = true
	elif facing_direction == -1:
		pressing_right = false
		pressing_left = true

func walk_away():
	if state != CharacterState.RECOVERY: block_legal = true
	if state == CharacterState.CROUCH or crouch_pressed: crouch_block_legal = true
	if facing_direction == 1:
		pressing_left = true
		pressing_right = false
	elif facing_direction == -1:
		pressing_right = true
		pressing_left = false

func jump_forward():
	pressing_left = false
	pressing_right = false
	uncrouch()
	walk_closer()
	pressing_jump = true
	await get_tree().create_timer(0.1).timeout
	pressing_jump = false
	pressing_left = false
	pressing_right = false

func jump_away():
	uncrouch()
	walk_away()
	pressing_jump = true
	await get_tree().create_timer(0.2).timeout
	pressing_jump = false
	pressing_left = false
	pressing_right = false

func dash_away():
	if (dash_available == false): return
	if disabled: return
	uncrouch()
	if state == CharacterState.IDLE or state == CharacterState.WALK or state == CharacterState.JUMP:
		if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN):
			if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
				start_dash(facing_direction * -1)
		dash_direction = facing_direction * -1

func dash_towards():
	if (dash_available == false): return
	if disabled: return
	uncrouch()
	if state == CharacterState.IDLE or state == CharacterState.WALK or state == CharacterState.JUMP:
		if dashes_left == 1 and (current_time - last_dash_time >= DASH_COOLDOWN):
			if (not is_on_floor() and MIDAIR_DASH) or (is_on_floor()):
				start_dash(facing_direction)
		dash_direction = facing_direction

func crouch():
	crouch_pressed = true

func uncrouch():
	crouch_pressed = false

func block(time):
	if get_random_number() < 20:
		walk_away()
		await get_tree().create_timer(time).timeout
		pressing_left = false
		pressing_right = false

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

func find_crouch():
	if enemy_state == CharacterState.CROUCH or enemy_state == CharacterState.CPUNCH or enemy_state == CharacterState.CKICK:
		enemy_crouching = true
	else:
		enemy_crouching = false

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

func get_random_number() -> int:
	return randi() % 100 + 1

# ---- Base overrides that use the booleans (unchanged) ----
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

func crouch_state(_direction):
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
	if disabled: return
	if punch_pressed:
		if crouch_pressed and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			start_action(crouch_punch_data["startup_frames"], func():
				if state == CharacterState.STARTUP: start_c_punch()
			, crouch_punch_data["startup_animation"])
		elif not crouch_pressed and state != CharacterState.CROUCH:
			stop_all_timers()
			start_action(punch_data["startup_frames"], func():
				if state == CharacterState.STARTUP: start_punch()
			, punch_data["startup_animation"])

	if kick_pressed:
		if crouch_pressed and (state == CharacterState.CROUCH or state == CharacterState.RECOVERY):
			stop_all_timers()
			animation_player.position.x = 18
			ShirtLayer.position.x = 18
			PantsLayer.position.x = 18
			crouch_scale()
			start_action(crouch_kick_data["startup_frames"], func():
				if state == CharacterState.STARTUP: start_c_kick()
			, crouch_kick_data["startup_animation"])
		elif not crouch_pressed and state != CharacterState.CROUCH:
			print("CPU isn't pressing crouch or in the crouch state!")
			stop_all_timers()
			animation_player.position.x = 18
			ShirtLayer.position.x = 18
			PantsLayer.position.x = 18
			reset_scale()
			start_action(kick_data["startup_frames"], func():
				if state == CharacterState.STARTUP: start_kick()
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
	if dead: return
	change_state(CharacterState.RECOVERY)
	animation_player.play(animation)
	PantsLayer.play(animation)
	ShirtLayer.play(animation)
	recovery_timer = frames * FRAME
	recovery_continuation = func():
		if state != CharacterState.STARTUP and state != CharacterState.HURT:
			if crouch_pressed:
				change_state(CharacterState.CROUCH)
			else:
				change_state(CharacterState.IDLE)

func report_dead():
	SfxManager.playDeath()
	cpu_died.emit()
