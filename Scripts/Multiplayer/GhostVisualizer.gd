extends Node2D
@onready var gsm := get_node_or_null("../GameStateManager")
@onready var sprite_local := get_node_or_null("../Player")
@onready var sprite_online := get_node_or_null("../Player1")

func _ready() -> void:
	if gsm:
		gsm.positions_updated.connect(_on_positions)
		_on_positions(gsm.players_pos)

func _on_positions(pos: Dictionary) -> void:
	var my_id: int = multiplayer.get_unique_id()
	for pid in pos.keys():
		var pid_i: int = int(pid)                # <- coerce
		var p := String(pos[pid])
		if pid_i == my_id:
			sprite_local.position = p
			#implement handling for local player input
		else:
			sprite_online.position = p
			#implement handling for online player input


func _process(_delta):
	if gsm == null:
		return

	# Get current simulated positions
	if gsm.players_pos.size() > 0:
		for pid in gsm.players_pos.keys():
			var pos: Vector2i = gsm.players_pos[pid]

			if pid == multiplayer.get_unique_id():
				sprite_local.position = pos
				#implement handling for local player input
			else:
				sprite_online.position = pos
				#implement handling for online player input
