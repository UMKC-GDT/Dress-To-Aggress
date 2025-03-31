extends Resource

class_name Wearable

@export_category("Clothing Properties")
@export_enum("BASE", "LEGWEAR", "SHIRT", "ACCESSORY") var ClothingType: String = "BASE"
@export_enum("BASE", "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC") var Rarity: String = "BASE"
@export var name: String
@export var outfitSet: String
@export var outfitPattern: String
@export var description: String
@export var color: Color
@export var stylePoints: int
@export var styleMultiplier: float #x.x multiplier

@export_category("Fighting Information") # All use x.x multiplier
@export var attackDamageChange: float = 1
@export var attackSpeedChange: float = 1
@export var defenseChange: float = 1
@export var walkSpeedChange: float = 1
@export var dashSpeedChange: float = 1
@export var jumpHeightChange: float = 1
@export var hitstunLengthChange: float = 1
@export var knockbackChange: float = 1

@export_category("Animation Frames")
@export var mirrorPose: Texture2D
@export var idlePose0: Texture2D
@export var idlePose1: Texture2D
@export var walkPose0: Texture2D
@export var walkPose1: Texture2D
@export var walkPose2: Texture2D
@export var walkPose3: Texture2D
@export var kickPose0: Texture2D
@export var kickPose1: Texture2D
@export var punchPose0: Texture2D
@export var punchPose1: Texture2D
@export var blockPose: Texture2D
@export var hurtPose: Texture2D
@export var Pose28: Texture2D

# Clothing Properties getters
func get_clothing_type() -> String:
	return ClothingType

func get_rarity() -> String:
	return Rarity

func get_outfit_name() -> String:
	return name

func get_outfit_set() -> String:
	return outfitSet

func get_outfit_pattern() -> String:
	return outfitPattern

func get_description() -> String:
	return description

func get_color() -> Color:
	return color

func get_style_points() -> int:
	return stylePoints

func get_style_multiplier() -> float:
	return styleMultiplier

# Fighting Information getters
func get_attack_damage_change() -> float:
	return attackDamageChange

func get_attack_speed_change() -> float:
	return attackSpeedChange

func get_defense_change() -> float:
	return defenseChange

func get_walk_speed_change() -> float:
	return walkSpeedChange

func get_dash_speed_change() -> float:
	return dashSpeedChange

func get_jump_height_change() -> float:
	return jumpHeightChange

func get_hitstun_length_change() -> float:
	return hitstunLengthChange

func get_knockback_change() -> float:
	return knockbackChange

# Animation Frames getters
func get_mirror_pose() -> Texture2D:
	return mirrorPose

func get_idle_pose0() -> Texture2D:
	return idlePose0

func get_idle_pose1() -> Texture2D:
	return idlePose1

func get_walk_pose0() -> Texture2D:
	return walkPose0
	
func get_walk_pose1() -> Texture2D:
	return walkPose1
	
func get_walk_pose2() -> Texture2D:
	return walkPose2
	
func get_walk_pose3() -> Texture2D:
	return walkPose3
	
func get_block_pose() -> Texture2D:
	return blockPose

func get_kick_pose0() -> Texture2D:
	return kickPose0

func get_kick_pose1() -> Texture2D:
	return kickPose1

func get_punch_pose0() -> Texture2D:
	return punchPose0

func get_punch_pose1() -> Texture2D:
	return punchPose1

func get_hurt_pose() -> Texture2D:
	return hurtPose

func get_pose28() -> Texture2D:
	return Pose28
