extends Node

# ---- Wiring ----
@export var gsm_path: NodePath = NodePath("..")
@onready var gsm: Node = get_node_or_null(gsm_path)

func _ready() -> void:
	if gsm == null:
		push_error("GhostPunchVisualizer: missing GameStateManager at gsm_path")
		set_process(false)
		print("No GSM on the Network Input Manager")
		return

	if gsm.has_signal("server_tick_inputs"):
		gsm.connect("server_tick_inputs", Callable(self, "_on_server_tick_inputs"))
		print("Connected signal from GSM to NIM")
	else:
		push_error("GhostPunchVisualizer: GSM missing 'server_tick_inputs'")
		set_process(false)

# --- Handler: authoritative inputs each tick ---
# inputs: { pid -> { "x": int, "y": int, "player_punch": bool } }
func _on_server_tick_inputs(tick: int, inputs: Dictionary) -> void:
	for k in inputs.keys():
		var pid: int = int(k)
		var inp: Dictionary = inputs[k]

		var vx: int = int(inp.get("x", 0))
		for l in inp:
			match l:
				"player_punch":
					if(!inp[l]): continue
					print("Player: " + str(pid) + " punched")
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
