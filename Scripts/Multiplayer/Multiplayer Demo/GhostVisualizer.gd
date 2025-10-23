extends Node2D
# Visual-only: moves one sprite per pid from authoritative inputs.
# Flashes white on punch, purple if a later correction clears a punch for the same (tick,pid).

# ---- Wiring ----
@export var gsm_path: NodePath = NodePath("..")
@export var sprite_scene: PackedScene = null
@onready var gsm: Node = get_node_or_null(gsm_path)

# ---- Visuals ----
@export var local_color: Color  = Color(0.3, 1.0, 0.4)
@export var remote_color: Color = Color(1.0, 0.4, 0.4)
@export var punch_flash_color: Color = Color(1, 1, 1)
@export var rollback_flash_color: Color = Color(0.6, 0.3, 1.0)
@export var punch_flash_seconds: float = 1.0
@export var rollback_flash_seconds: float = 1.0

# ---- Motion ----
@export var speed_per_tick: int = 6
@export var smoothing: float = 0.0

# Optional trails
@export var use_trails: bool = false
@export var trail_len: int = 16
@export var trail_color: Color = Color(1, 1, 1, 0.35)

# ---- State (untyped; cast on read) ----
var actors: Dictionary = {}               # pid -> Node2D
var targets: Dictionary = {}              # pid -> Vector2
var trails: Dictionary = {}               # pid -> Line2D
var base_colors: Dictionary = {}          # pid -> Color
var punch_flash_until: Dictionary = {}    # pid -> float
var rollback_flash_until: Dictionary = {} # pid -> float
var punch_seen_by_tick: Dictionary = {}   # tick -> { pid -> bool }

func _ready() -> void:
	if gsm == null:
		push_error("GhostPunchVisualizer: missing GameStateManager at gsm_path")
		set_process(false)
		return

	if gsm.has_signal("server_tick_inputs"):
		gsm.connect("server_tick_inputs", Callable(self, "_on_server_tick_inputs"))
	else:
		push_error("GhostPunchVisualizer: GSM missing 'server_tick_inputs'")
		set_process(false)

func _process(delta: float) -> void:
	if smoothing > 0.0:
		var step: float = clamp(delta / smoothing, 0.0, 1.0)
		for pid in targets.keys():
			if actors.has(pid):
				var a: Node2D = actors[pid] as Node2D
				if a == null:
					continue
				var tgt: Vector2 = targets[pid] if targets.has(pid) else a.position
				a.position = a.position.lerp(tgt, step)

	var now: float = Time.get_unix_time_from_system()
	for pid in actors.keys():
		var base: Color = base_colors.get(pid, remote_color)
		var color: Color = base
		var rb_until: float = float(rollback_flash_until.get(pid, 0.0))
		var p_until: float = float(punch_flash_until.get(pid, 0.0))
		if now < rb_until:
			color = rollback_flash_color
		elif now < p_until:
			color = punch_flash_color
		var ci: CanvasItem = actors[pid] as CanvasItem
		if ci != null:
			ci.modulate = color

# --- Handler: authoritative inputs each tick ---
# inputs: { pid -> { "x": int, "y": int, "player_punch": bool } }
func _on_server_tick_inputs(tick: int, inputs: Dictionary) -> void:
	if not punch_seen_by_tick.has(tick):
		punch_seen_by_tick[tick] = {}
	var prev_tick_map: Dictionary = punch_seen_by_tick[tick]

	for k in inputs.keys():
		var pid: int = int(k)
		var inp: Dictionary = inputs[k]

		var vx: int = int(inp.get("x", 0))
		var vy: int = int(inp.get("y", 0))
		var punch_now = false
		for l in inp:
			match l:
				"player_punch":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " punched")
					punch_now = true
				"player_kick":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " kicked")
				"player_jump":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " jumped")
				"player_throw":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " is throwing")
				"player_crouch":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " crouched")

		var actor: Node2D = _get_or_make_actor(pid)

		var current_target: Vector2 = Vector2(targets[pid]) if targets.has(pid) else actor.position
		var new_target: Vector2 = current_target + Vector2(vx, vy) * float(speed_per_tick)
		targets[pid] = new_target
		if smoothing <= 0.0:
			actor.position = new_target
		if use_trails:
			_update_trail(pid, actor.position)

		if punch_now:
			punch_flash_until[pid] = Time.get_unix_time_from_system() + punch_flash_seconds

		var prev_was_true: bool = bool(prev_tick_map.get(pid, false))
		if prev_tick_map.has(pid) and prev_was_true and not punch_now:
			rollback_flash_until[pid] = Time.get_unix_time_from_system() + rollback_flash_seconds
			punch_flash_until[pid] = 0.0

		prev_tick_map[pid] = punch_now

	_prune_old_tick_history(tick)

# ---------------- helpers ----------------
func _get_or_make_actor(pid: int) -> Node2D:
	if actors.has(pid):
		var existing: Node2D = actors[pid] as Node2D
		if existing != null:
			return existing

	var node: Node2D
	if sprite_scene != null:
		node = sprite_scene.instantiate() as Node2D
	else:
		var s: Sprite2D = Sprite2D.new()
		var img: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.9, 0.9, 0.9))
		s.texture = ImageTexture.create_from_image(img)
		node = s

	var base: Color = remote_color
	if pid == multiplayer.get_unique_id():
		base = local_color
	base_colors[pid] = base
	var ci: CanvasItem = node as CanvasItem
	if ci != null:
		ci.modulate = base

	add_child(node)
	actors[pid] = node
	targets[pid] = node.position

	if use_trails:
		var ln: Line2D = Line2D.new()
		ln.width = 2.0
		ln.default_color = trail_color
		add_child(ln)
		trails[pid] = ln

	return node

func _update_trail(pid: int, p: Vector2) -> void:
	if not use_trails or not trails.has(pid):
		return
	var ln: Line2D = trails[pid] as Line2D
	if ln == null:
		return
	var pts: PackedVector2Array = ln.points
	pts.append(p)
	while pts.size() > trail_len:
		pts.remove_at(0)
	ln.points = pts

func _prune_old_tick_history(current_tick: int) -> void:
	var keep_from: int = max(0, current_tick - 180) # ~3s @ 60Hz
	var to_erase: Array = []
	for t in punch_seen_by_tick.keys():
		if int(t) < keep_from:
			to_erase.append(t)
	for t in to_erase:
		punch_seen_by_tick.erase(t)
