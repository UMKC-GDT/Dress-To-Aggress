extends Node2D

func _ready() -> void:
	$RichTextLabel.text = ""

func _on_player_one_died() -> void:
	print("Player One Died. Bozo.")
	$RichTextLabel.text = "You Lose. Try Again!"
	$RichTextLabel/Timer.start()
	
func _on_cpu_died() -> void:
	print("CPU Died. Nice Job!")
	$RichTextLabel.text = "You Win! Congratulations, the villains have been stopped!"
	$RichTextLabel/Timer.start()

func _on_timer_timeout() -> void:
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/main_menu.tscn")
