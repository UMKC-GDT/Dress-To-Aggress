extends Node2D

@export var dressupTimer: float

@export var speech_text: Node2D


var pants_text :String
var shirt_text :String
#var file : FileAccess 
var save_resource: Resource 

func _ready() -> void:
	#default clothes if none were picked (we might change this)
	pants_text =  "grayShorts"
	shirt_text = "grayShirtS"
	
	speech_text.visible = false;
	$"../AudioStreamPlayer".play(12.0)
	
	#open save file
	#file  = FileAccess.open("res://Assets/OutfitSaveFile.txt", FileAccess.READ_WRITE) #delete soon
	save_resource = preload("res://Assets/Resources/OutfitSaveResource.tres")
	
	#$Timer.start(dressupTimer)
	
	# Stops and hides timer (Band-aid solution to removing timer)
	#$Timer.paused = true;
	visible = false;

# No longer used because the timer is turned off
#func _process(delta: float) -> void:
	#
	#$RichTextLabel.text = str($Timer.time_left).pad_decimals(2)
	#
	#if(str($Timer.time_left).pad_decimals(2) == "9.50"):
		#var tween = get_tree().create_tween()
		#speech_text.visible = true;
		#tween.tween_property(speech_text, "scale", Vector2(1.1,1.1), .1)
		#tween.tween_property(speech_text, "scale", Vector2(1,1), .1)
	#if(str($Timer.time_left).pad_decimals(2) == "7.50"):
		#speech_text.visible = false;
	

func toStage() -> void:
	#results is the array of clothing items that are one the player
	var results = get_last_outfit();
	print(results)
	
	#for key in results:
		#print(key.collider.get_parent().name)
	#for r in range(0,results.size()-1):
	#	shirt_text = results[r].collider.get_parent().current_wearable.get_outfit_name()
	#	print(shirt_text)
	
	#rersult size will include the background so size of 2  means one clothing item
	if results.size() == 2:
		#if  there is only one, save one that was  added, then the other is default
		var clothing_name = results[1].collider.get_parent().current_wearable.get_outfit_name()
		# DEBUG: print("T1: " + clothing_name)
		
		if (clothing_name.contains("Shirt")):
			shirt_text = clothing_name
			# DEBUG: print("T1.5: " + shirt_text)
		elif (clothing_name.contains("Pants") || clothing_name.contains("Shorts")):
			pants_text = clothing_name
			# DEBUG: print("T2: " + pants_text)
		
	if results.size() >= 3:
		#this  makes sure were only getting one shirt and one pants if  there is more than one 
		for i in range(1,results.size()):
			var current_clothing = results[i].collider.get_parent().current_wearable.get_outfit_name()
			if(current_clothing.contains("Shirt")):
				shirt_text = current_clothing
				# DEBUG: print("T3: " + shirt_text)
			else:
				pants_text = current_clothing
			
			print(current_clothing)
		#print(pants_text)
		
	#save file, must  separate with two commas
	#file.store_string(pants_text+","+shirt_text+",") #delete soon
	save_resource.set_shirt_text(shirt_text)
	save_resource.set_pants_text(pants_text)
	#print(file.get_as_text())
	
	#open new file
	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Scenes/stageFight.tscn") #replace with fighting scene


#returns array  of clothingn items that are currently overlapping the platform
func get_last_outfit() -> Array[Dictionary]:
	var space_state = get_world_2d().direct_space_state
	
	# Creates 2 points for the area where the top and bottom items should be
	var topItemQuery = PhysicsPointQueryParameters2D.new()
	var bottomItemQuery = PhysicsPointQueryParameters2D.new()
	
	# Since the y position for the platform is -21, We want the y to be -90 to match where the upper torso is
	topItemQuery.position = $"../Platform".position + Vector2(0,-69)
	topItemQuery.collide_with_bodies = true  # Adjust as needed
	topItemQuery.collide_with_areas = true
	
	# No need to adjust position, position of the platform is already at waist level
	bottomItemQuery.position = $"../Platform".position
	bottomItemQuery.collide_with_bodies = true  # Adjust as needed
	bottomItemQuery.collide_with_areas = true
	
	# Puts all objects colliding with the intersection points into a single list
	var topResults = space_state.intersect_point(topItemQuery)
	var bottomResults = space_state.intersect_point(bottomItemQuery)

	var results: Array[Dictionary] = []
	var resultsTemp = []
	resultsTemp.append_array(topResults)
	resultsTemp.append_array(bottomResults)
	
	# Checks for any duplicates in resultsTemp, if it's not a duplicate, append it to results list
	var seen_ids = {}
	for collision in resultsTemp:
		if "collider" in collision:
			var collider_id = collision["collider"].get_instance_id()
			if not seen_ids.has(collider_id):
				seen_ids[collider_id] = true
				results.append(collision)
	
	# Note: return bottomResults instead if you want to go back to the old system.
	return results

func _on_to_stage_button_button_down():
	toStage();
