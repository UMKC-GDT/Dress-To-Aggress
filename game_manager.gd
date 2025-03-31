extends Node2D

var tree: SceneTree = get_tree()

func _on_timer_timeout() -> void:
	$"../Player".disabled = true
	$"../Player2".disabled = true
	$RichTextLabel.text = "You Weren't Quick Enough. The Drugs Got Distributed."

func _on_player_one_died() -> void:
	$RichTextLabel.text = "You Lose. Try Again!"
	$"RichTextLabel/Win_Lose Timer".start()
	
func _on_cpu_died() -> void:
	$RichTextLabel.text = "You Win! Congratulations, the villains have been stopped!"
	$"RichTextLabel/Win_Lose Timer".start()

func _on_win_lose_timer_timeout() -> void:
	tree.change_scene_to_file("res://Scenes/main_menu.tscn")
