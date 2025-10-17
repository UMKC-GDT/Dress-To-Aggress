extends Node
@onready var lobby_ui: Node = get_parent()  # the LobbyScene with LobbyUI.gd

@export var autostart: bool = true

func _ready():
	if autostart == false: return
	var role := _get_role()
	print(role)
	if role == "Host": 
		lobby_ui._on_ButtonHost_pressed()
	elif role == "Client": 
		lobby_ui._on_ButtonJoin_pressed()
	if role == "Host": 
		await get_tree().create_timer(2).timeout
		lobby_ui._on_start_pressed()

func _get_role() -> String:
	var args := OS.get_cmdline_args()
	for i in args.size():
		var a := String(args[i]).strip_edges()
		if a == "--":
			continue
		while a.begins_with("-"):
			a = a.substr(1)

		if a.find("=") != -1:
			var k := a.get_slice("=", 0).to_lower()
			var v := a.get_slice("=", 1).strip_edges().trim_prefix('"').trim_suffix('"')
			if k == "role":
				return v
		elif a.to_lower() == "role" and i + 1 < args.size():
			var v := String(args[i + 1]).strip_edges().trim_prefix('"').trim_suffix('"')
			return v
	return ""
