extends Node2D

var last_clicked


var draggable = false
var is_inside_dropable = false
var body_ref
var offset: Vector2
var initialPos: Vector2
var collider : CollisionShape2D

func _process(delta):
	if ( last_clicked is RigidBody2D):
		if Input.is_action_just_pressed("click"):
			
			initialPos = last_clicked.global_position
			offset = get_viewport().get_mouse_position() - last_clicked.global_position
			global.is_dragging = true
			
			print("click")
			
		if Input.is_action_pressed("click"):
			last_clicked.global_position = get_viewport().get_mouse_position()  - offset
			#print("follow mouse")
			
		elif Input.is_action_just_released("click"):
			print("release")
			global.is_dragging = false 
			var tween = get_tree().create_tween()
			if last_clicked.get_child(1).is_inside_dropable:
				print("in platform")
				last_clicked.gravity_scale = 0.0
				tween.tween_property(last_clicked, "position", last_clicked.get_child(1).body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
				
				#last_clicked.position = last_clicked.get_child(1).body_ref.position
			else:
				print("leave")
				last_clicked.gravity_scale = 1.0

	

func _input(event):
	# Check for left mouse button press
	
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
			print(last_clicked.name)
			
			
			
			
			
