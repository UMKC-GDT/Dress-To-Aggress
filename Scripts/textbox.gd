extends Control

var sentence = "*You are a secret agent, infiltrating an international drug smuggling ring. 
\n*But it's all hidden... behind a fashion show? 
\n*You're going to need your sharpest disguise - the fiercest outfit you can imagine."

var sen_index = 0

func _on_timer_timeout() -> void:
	if sen_index<sentence.length():
		$Panel/Label.text += sentence[sen_index]
		sen_index+=1
	else:
		change_scene()

func change_scene() -> void:
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://Scenes/DressUp.tscn")
