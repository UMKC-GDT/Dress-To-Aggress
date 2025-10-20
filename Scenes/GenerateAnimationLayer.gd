extends AnimatedSprite2D


@export var current_wearable: Wearable


@onready
var animation_player: AnimatedSprite2D


func  _ready() -> void:
	animation_player = self
	
	var shirt_text :String
	var pants_text : String
	
	var rng = RandomNumberGenerator.new()
	
	if(get_parent().name == "Player2" and global.arcade_level < 1):
		#generate a random outfit
		var pants = ClothingDatabase.pants_list
		var shirts = ClothingDatabase.shirts_list
		var rand1 = rng.randi_range(0,pants.size()-2)
		var rand2 = rng.randi_range(0,shirts.size()-2)
		pants_text = pants[rand1]
		shirt_text =  shirts[rand2]
		
	elif(get_parent().name == "Player2"):
		match global.arcade_level:
			1: shirt_text = "grayShirtS"; pants_text = "grayShorts"
			2: shirt_text = "brownShirtL"; pants_text = "bluePants"
			3: shirt_text = "greenShirtS"; pants_text = "greenPants"
			4: shirt_text = "whiteShirtL"; pants_text = "whiteShorts"
			5: shirt_text = "purpleShirtL"; pants_text = "purplePants"
			6: shirt_text = "blackShirtL"; pants_text = "blackShorts"
			7: shirt_text = "redShirtL"; pants_text = "redPants"
	else:
		#get the clothing items to generate from the save file
		#var textFile = "res://Assets/OutfitSaveFile.txt"
		#var file  = FileAccess.open(textFile, FileAccess.READ)
		#shirt_text =  file.get_as_text().get_slice(",",1)
		#pants_text =  file.get_as_text().get_slice(",",0)
		
		var save_resource = preload("res://Assets/Resources/OutfitSaveResource.tres")
		shirt_text = save_resource.get_shirt_text()
		pants_text = save_resource.get_pants_text()
	 
	
	#load pants
	if self.name == "PantsLayer":
		self.current_wearable = load("res://Assets/Resources/Wearables/"+pants_text+".tres")
		
	#load shirt
	if self.name == "ShirtLayer":
		self.current_wearable = load("res://Assets/Resources/Wearables/"+shirt_text+".tres")
	
	#set postion to the body (might have   to adjust when merges wit htomies movement)
	#self.position  = $"../Body".position
	self.scale = Vector2(0.3,0.3)  #can be chaanged
	self.modulate = current_wearable.color
	 
	
	#create the animations on this layer for each animation (might change or add more  when adapting to tommies)
	animation_player.sprite_frames = SpriteFrames.new()
	createAnimation("block")
	createAnimation("dash left")
	createAnimation("dash right")
	createAnimation("dead")
	createAnimation("hurt")
	createAnimation("idle")
	createAnimation("jump")
	createAnimation("jump startup")
	createAnimation("kick startup")
	createAnimation("kick")
	createAnimation("kick recovery")
	createAnimation("pose")
	createAnimation("pose recovery")
	createAnimation("walk backward")
	createAnimation("walk forward")
	createAnimation("punch startup")
	createAnimation("punch")
	createAnimation("punch recovery")
	createAnimation("crouch punch startup")
	createAnimation("crouch punch")
	createAnimation("crouch punch recovery")
	createAnimation("crouch kick startup")
	createAnimation("crouch kick")
	createAnimation("crouch kick recovery")
	

func createAnimation(anim_name: String):
	
	#set each animation with the frames from the wearable object that was loaded
	animation_player.sprite_frames.add_animation(anim_name)
	
	if(anim_name =="block"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="dash left"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="dash right"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="dead"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 0.7)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_knockOut_pose0(), 0.7)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_knockOut_pose1(), 0.7)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_knockOut_pose2(), 35.0)
	if(anim_name =="hurt"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_hurt_pose(), 1.0)
	if(anim_name =="idle"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose1(), 1.0)
	if(anim_name =="jump"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
	if(anim_name =="jump startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="kick startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
	if(anim_name =="kick"):
		#animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose1(), 1.0)
	if(anim_name =="kick recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
	if(anim_name =="pose"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_pose28(), 1.0)
	if(anim_name =="pose recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_hurt_pose(), 1.0)
	if(anim_name =="walk backward"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose1(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose2(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose3(), 1.0)
	if(anim_name =="walk forward"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose1(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose2(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_walk_pose3(), 1.0)
	if(anim_name =="punch startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose0(), 1.0)
	if(anim_name =="punch"):
		#animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose1(), 1.0)
	if(anim_name =="punch recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose0(), 1.0)
		
	if(anim_name =="crouch punch startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_punch_pose0(), 1.0)
	if(anim_name =="crouch punch"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_punch_pose2(), 1.0)
	if(anim_name =="crouch punch recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_punch_pose1(), 1.0)
	if(anim_name =="crouch kick startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_kick_pose1(), 1.0)
	if(anim_name =="crouch kick"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_kick_pose1(), 1.0)
	if(anim_name =="crouch kick recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_crouch_kick_pose1(), 1.0)
	
	
	
	animation_player.sprite_frames.set_animation_loop(anim_name, true)
	animation_player.sprite_frames.set_animation_speed(anim_name, 5.0)
	
	

#this is temporary,  changne it to adapt tot Tommies controls 
#func _physics_process(delta: float):
	#if Input.is_action_pressed("Key_S"):
		#animation_player.play("kick")
	#elif Input.is_action_pressed("Key_A"):
		#animation_player.play("walk")
	#elif Input.is_action_pressed("Key_D"):
		#animation_player.play("punch")
	#else:
		#animation_player.play("idle")
		#
	##goes back to the dress up scene
	#if Input.is_action_pressed("Space"):
		#var tree: SceneTree = get_tree()
		#tree.change_scene_to_file("res://Scenes/DressUp.tscn") #replace with fighting scene
#
	#
