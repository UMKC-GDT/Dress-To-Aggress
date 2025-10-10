extends Node2D
@onready var gsm := get_node_or_null("../GameStateManager")
@onready var sprite_local := get_node_or_null("../Sprite2D_Local")
@onready var sprite_online := get_node_or_null("../Sprite2D_Online")

func _ready() -> void:
	if gsm:
		gsm.positions_updated.connect(_on_positions)
		_on_positions(gsm.players_pos)
	sprite_local.modulate = Color.GREEN
	sprite_online.modulate = Color.RED

func _on_positions(pos: Dictionary) -> void:
	var my_id: int = multiplayer.get_unique_id()
	for pid in pos.keys():
		var pid_i: int = int(pid)                # <- coerce
		var p := Vector2(pos[pid])
		if pid_i == my_id:
			sprite_online.position = p
		else:
			sprite_local.position = p


func _process(_delta):
	if gsm == null:
		return

	# Get current simulated positions
	if gsm.players_pos.size() > 0:
		for pid in gsm.players_pos.keys():
			var pos: Vector2i = gsm.players_pos[pid]

			if pid == multiplayer.get_unique_id():
				sprite_local.position = pos
			else:
				sprite_online.position = pos
