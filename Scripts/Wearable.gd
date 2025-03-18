extends Resource

class_name Wearable

@export_category("Clothing Properties")

@export_enum("BASE", "LEGWEAR", "SHIRT", "SHOES", "ACCESSORY") var ClothingType: String = "BASE"
@export_enum("BASE", "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY") var Rarity: String = "BASE"

@export var attackDamageChange: int
@export var stylePoints: int
@export var styleMultiplier: float
@export var speedChange: int

@export_category("Clothing Information")
@export var outfitSet: String
@export var outfitPattern: String

@export_category("Animation Frames")
@export var idlePose: Texture2D
@export var walkPose1: Texture2D
@export var blockPose: Texture2D
@export var kickPose: Texture2D
@export var punchPose: Texture2D
@export var hurtPose: Texture2D
@export var Pose28: Texture2D

func get_clothing_type() -> String:
	return ClothingType
	
func get_rarity() -> String:
	return Rarity
	
func get_attack_damage_change() -> int:
	return attackDamageChange

func get_style_points() -> int:
	return stylePoints

func get_style_multiplier() -> float:
	return styleMultiplier

func get_speed_change() -> int:
	return speedChange

func get_outfit_set() -> String:
	return outfitSet

func get_outfit_pattern() -> String:
	return outfitPattern

func get_idle_pose() -> Texture2D:
	return idlePose

func get_walk_pose1() -> Texture2D:
	return walkPose1
	
func get_block_pose() -> Texture2D:
	return blockPose

func get_kick_pose() -> Texture2D:
	return kickPose

func get_punch_pose() -> Texture2D:
	return punchPose

func get_hurt_pose() -> Texture2D:
	return hurtPose

func get_pose28() -> Texture2D:
	return Pose28
