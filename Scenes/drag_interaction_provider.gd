extends Node2D


var last_clicked

var draggable = false
var is_inside_dropable = false
var body_ref
var offset: Vector2
var initialPos: Vector2
var collider : CollisionShape2D
var shirt_item_can_enter: Node = null
var pant_item_can_enter: Node = null


func _process(_delta):
	if ( last_clicked is Area2D):
		if Input.is_action_just_pressed("click"):
			
			initialPos = last_clicked.global_position
			offset = get_viewport().get_mouse_position() - last_clicked.global_position
			global.is_dragging = true
			
			print("click")
			
		if Input.is_action_pressed("click"):
			last_clicked.get_parent().global_position = get_viewport().get_mouse_position()  - offset
			#print("follow mouse")
			
		elif Input.is_action_just_released("click"):
			print("release")
			global.is_dragging = false 
			var tween = get_tree().create_tween()
			is_inside_dropable = last_clicked.get_parent().is_inside_dropable
			
			if is_inside_dropable:
				
				print("in platform")
				#last_clicked.gravity_scale = 0.0
				#if ("Shirt" in last_clicked.get_parent().name):
				if shirt_item_can_enter == null and "Shirt" in last_clicked.get_parent().name :
					tween.tween_property( last_clicked.get_parent(), "position",  last_clicked.get_parent().body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
					shirt_item_can_enter = last_clicked
					
				elif pant_item_can_enter == null and "Pants" in last_clicked.get_parent().name :
					tween.tween_property( last_clicked.get_parent(), "position",  last_clicked.get_parent().body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
					pant_item_can_enter = last_clicked
				else:
					tween.tween_property( last_clicked.get_parent(), "position",  Vector2(randf_range(100, 200),randf_range(0,100)), 0.2).set_ease(Tween.EASE_OUT)
				#last_clicked.position = last_clicked.get_parent().body_ref.position
			else:
				print("leave")
				if shirt_item_can_enter == last_clicked and "Shirt" in last_clicked.get_parent().name  :
					shirt_item_can_enter = null
					
				if pant_item_can_enter == last_clicked and "Pants" in last_clicked.get_parent().name:
					pant_item_can_enter = null
				
				#tween.tween_property( last_clicked.get_parent(), "position",initialPos, 0.2).set_ease(Tween.EASE_OUT)
				
				#last_clicked.gravity_scale = 1.0
			last_clicked = self


func _input(event):
	
	#get the object that is clicked
	if event is InputEventMouseButton and Input.is_action_just_pressed("click") and event.pressed:
			# Get the mouse position in global (world) coordinates
		var mouse_pos: Vector2 = get_global_mouse_position()
			# Perform a collision query at the mouse position
		var space_state = get_world_2d().direct_space_state
		
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collide_with_bodies = true  # Adjust as needed
		query.collide_with_areas = true
		
		var results = space_state.intersect_point(query)
			# If any collider was found at this point, print the first one's name
		if results.size() > 0:
			var clicked_object = results[0].collider
			last_clicked = clicked_object
			print("0",last_clicked.name)
			
		if results.size() > 1:
			var clicked_object = results[1].collider
			last_clicked = clicked_object
			print("1",results[1].collider.name)
