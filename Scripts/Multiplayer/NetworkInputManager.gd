extends Node

# ---- Wiring ----
@export var gsm_path: NodePath = NodePath("..")
@onready var gsm: Node = get_node_or_null(gsm_path)
@export var player1: CharacterBody2D
@export var player2: CharacterBody2D

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
		
		if(player1.pid == pid):
			player1.send_input(inp)
		else:
			player2.send_input(inp)
		
		
