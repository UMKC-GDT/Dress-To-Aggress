extends Node

var draggable = false
var is_inside_dropable = false
var body_ref : StaticBody2D
var offset: Vector2
var initialPos: Vector2
var started = false 
var platforms = 0
var stat_box : Panel

signal updateStatsBar(clothingObject, toDo)

@export var current_wearable: Wearable # WILL ERROR IF NO WEARABLE PRESENT

func _ready():
	
	#to make  sure that there is alwasy a pants and shirt option, the object is differeent babsed on the name
	if("randomPants" in self.name):
		set_random_pants_wearable()
	else:
		set_random_shirt_wearable()
	
	get_child(0).modulate = current_wearable.get_color()
	stat_box = get_child(2)
	stat_box.visible = false
	stat_box.get_child(0).text = current_wearable.get_description()
	$Sprite2D.texture = current_wearable.get_mirror_pose()


func get_current_wearable() -> Wearable:
	return current_wearable
	
func set_random_pants_wearable():
	var rng = RandomNumberGenerator.new()
	var path   =  "res://Assets/Resources/Wearables/"
	#this array  of pants must be the exact names  as the resources
	var pants = ClothingDatabase.pants_list
	
	#picks a random numbe
	var rand = rng.randi_range(0,pants.size()-1)
	
	#generates random pants
	current_wearable = load(path + pants[rand] + ".tres")
	
func set_random_shirt_wearable():
	var rng = RandomNumberGenerator.new()
	var path   =  "res://Assets/Resources/Wearables/"
	#this array  of shirts must be the exact names  as the resources
	var shirts = ClothingDatabase.shirts_list
	
	#picks a random number
	var rand = rng.randi_range(0,shirts.size()-1)
	
	#generates random shirt
	current_wearable = load(path + shirts[rand] + ".tres")
	
#when mouse hovers oveer the clothing 	
func _on_area_2d_mouse_entered():
	if not global.is_dragging:
		draggable = true
		self.scale = Vector2(1.05, 1.05)
		stat_box.visible = true
		updateStatsBar.emit(self, 0)

#when mouse shopts hovering over the clothing 
func _on_area_2d_mouse_exited():
	stat_box = get_child(2)
	if not global.is_dragging:
		draggable = false
		self.scale = Vector2(1, 1)
		stat_box.visible = false

#when clothing enters the platform
func _on_area_2d_body_entered(body: StaticBody2D):
	
	if (body.is_in_group('dropable') and platforms < 1):
		platforms += 1
		is_inside_dropable = true
		body.modulate = Color(Color.REBECCA_PURPLE, 0.2)
		body_ref = body
		

#when clothing leaves the platform
func _on_area_2d_body_exited(body):
	if body.is_in_group('dropable') and platforms == 1:
		platforms -= 1
		is_inside_dropable = false
		body.modulate  = Color(Color.MEDIUM_PURPLE, 0.0)
		
