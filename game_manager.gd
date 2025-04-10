extends Node2D

func _ready() -> void:
	$Message.text = ""
	$"Fight Timer Display".text = ""
	
func _process(delta: float) -> void:
	$"Fight Timer Display".text = str($"Fight Timer Display/Fight Timer".time_left).pad_decimals(1)

func _on_player_one_died() -> void:
	$Message.text = "You Lose. Try Again!"
	$Message/Timer.start()
	$"Fight Timer Display".visible = false
	$"../Player".disabled = true
	$"../Player2".disabled = true

func _on_cpu_died() -> void:
	$Message.text = "You Win! Congratulations!"
	$Message/Timer.start()
	$"Fight Timer Display".visible = false
	$"../Player".disabled = true
	$"../Player2".disabled = true

func _on_timer_timeout() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/DressUp.tscn")


func _on_fight_timer_timeout() -> void:
	$Message.text = "Time Ran Out. Try Again!"
	$Message/Timer.start()
	$"Fight Timer Display".visible = false
