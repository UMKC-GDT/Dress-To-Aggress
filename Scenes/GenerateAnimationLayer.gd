extends AnimatedSprite2D


@export var current_wearable: Wearable


@onready
var animation_player: AnimatedSprite2D


func  _ready() -> void:

	animation_player = self
	
	#get the clothing items to generate from the save file
	var textFile = "res://Assets/OutfitSaveFile.txt"
	var file  = FileAccess.open(textFile, FileAccess.READ)
	var shirt_text =  file.get_as_text().get_slice(",",1)
	var pants_text =  file.get_as_text().get_slice(",",0)
	
	#load pants
	if self.name == "PantsLayer":
		self.current_wearable = load("res://Assets/Resources/Wearables/"+pants_text+".tres")
		
	#load shirt
	if self.name == "ShirtLayer":
		self.current_wearable = load("res://Assets/Resources/Wearables/"+shirt_text+".tres")
	
	#set postion to the body (might have   to adjust when merges wit htomies movement)
	#self.position  = $"../Body".position
	self.scale = Vector2(0.3,0.3)  #can  be chaanged
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
	createAnimation("kick")
	createAnimation("kick recovery")
	createAnimation("pose")
	createAnimation("pose recovery")
	createAnimation("walk backward")
	createAnimation("walk forward")
	createAnimation("punch")
	createAnimation("punch recovery")
	

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
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="hurt"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="idle"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose1(), 1.0)
	if(anim_name =="jump"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
	if(anim_name =="jump startup"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="kick"):
		#animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose1(), 1.0)
	if(anim_name =="kick recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_kick_pose0(), 1.0)
	if(anim_name =="pose"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
	if(anim_name =="pose recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_idle_pose0(), 1.0)
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
	if(anim_name =="punch"):
		#animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose0(), 1.0)
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose1(), 1.0)
	if(anim_name =="punch recovery"):
		animation_player.sprite_frames.add_frame(anim_name, current_wearable.get_punch_pose0(), 1.0)
	
	
	
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
