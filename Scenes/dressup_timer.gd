extends Node2D

@export var dressupTimer: float

@export var speech_text: Node2D


var pants_text :String
var shirt_text :String
var file : FileAccess

func _ready() -> void:
	#default clothes if none were picked (we might change this)
	pants_text =  "whiteShorts"
	shirt_text = "whiteShirt"
	
	speech_text.visible = false;
	
	
	#open save file
	file  = FileAccess.open("res://Assets/OutfitSaveFile.txt", FileAccess.READ_WRITE)
	
	$Timer.start(dressupTimer)
	
func _process(delta: float) -> void:
	
			
	$RichTextLabel.text = str($Timer.time_left).pad_decimals(2)
	
	if(str($Timer.time_left).pad_decimals(2) == "9.50"):
		var tween = get_tree().create_tween()
		speech_text.visible = true;
		tween.tween_property(speech_text, "scale", Vector2(1.1,1.1), .1)
		tween.tween_property(speech_text, "scale", Vector2(1,1), .1)
	if(str($Timer.time_left).pad_decimals(2) == "7.50"):
		speech_text.visible = false;
	

func _on_timer_timeout() -> void:
	#results is the array of clothing items that are one the player
	var results = get_last_outfit();
	
	#for key in results:
		#print(key.collider.get_parent().name)
	#for r in range(0,results.size()-1):
	#	shirt_text = results[r].collider.get_parent().current_wearable.get_outfit_name()
	#	print(shirt_text)
	
	#rersult size will include the background so size of 2  means one clothing item
	if results.size() == 2:
		#if  there is only one, save one that was  added, then the other is default
		var clothing_name = results[1].collider.get_parent().current_wearable.get_outfit_name()
		if (clothing_name.contains("Shirt")):
			shirt_text = clothing_name
		elif (clothing_name.contains("Pants")):
			pants_text = clothing_name
		
	if results.size() >= 3:
		#this  makes sure were only getting one shirt and one pants if  there is more than one 
		for i in range(1,results.size()):
			var current_clothing = results[i].collider.get_parent().current_wearable.get_outfit_name()
			if(current_clothing.contains("Shirt")):
				shirt_text = current_clothing
			else:
				pants_text = current_clothing
			
			print(current_clothing)
		#print(pants_text)
		
	#save file, must  separate with two commas
	file.store_string(pants_text+","+shirt_text+",")
	#print(file.get_as_text())
	
	#open new file
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/stageFight.tscn") #replace with fighting scene


#returns array  of clothingn items that are currently overlapping the platform
func get_last_outfit() -> Array[Dictionary]:
	var space_state = get_world_2d().direct_space_state
		
	var query = PhysicsPointQueryParameters2D.new()
	query.position = $"../Platform".position
	query.collide_with_bodies = true  # Adjust as needed
	query.collide_with_areas = true
		
	var results = space_state.intersect_point(query)
	
	return results
