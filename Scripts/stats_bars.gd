extends Node2D

var healthStat: int = 50
var speedStat: int = 50
var poseStat: int = 50
var damageStat: int = 50

@onready var healthBar: ProgressBar = $healthBar
@onready var healthChange: ProgressBar = $healthBar/changeBar
@onready var speedBar: ProgressBar = $speedBar
@onready var speedChange: ProgressBar = $speedBar/changeBar
@onready var damageBar: ProgressBar = $DamageBar
@onready var damageChange: ProgressBar = $DamageBar/changeBar
@onready var poseBar: ProgressBar = $PoseBar
@onready var poseChange: ProgressBar = $PoseBar/changeBar

func _ready() -> void:
	healthBar.value = healthStat
	healthChange.value = healthBar.value
	speedBar.value = speedStat
	speedChange.value = healthChange.value
	damageBar.value = damageStat
	damageChange.value = damageBar.value
	poseBar.value = poseStat
	poseChange.value = poseBar.value


func updateStatsBars(clickedObj, toDo):
	var changeArr = getAverageStatChange(clickedObj)
	
	print("Average speed change " + str(changeArr[0]))
	print("Average health change " + str(changeArr[1]))
	print("Average pose change " + str(changeArr[2]))
	print("Average damage change " + str(changeArr[3]))
	
	var speedDif = speedBar.value * (1 + changeArr[0])
	var healthDif = healthBar.value * (1 + changeArr[1])
	var damageDif = damageBar.value * (1 + changeArr[2])
	var poseDif = poseBar.value * (1 + changeArr[3])
	print(speedDif)
	print(healthDif)
	print(damageDif)
	print(poseDif)
	
	show_increase(speedChange, speedDif)
	show_increase(healthChange, healthDif)
	show_increase(damageChange, damageDif)
	show_increase(poseChange, poseDif)


func getAverageStatChange(clickedObj) -> Array:
	var clothing = clickedObj.current_wearable
	var speedAvg = 0
	var healthAvg = 0
	var poseAvg = 0
	var damageAvg = 0
	
	speedAvg += clothing.get_walk_speed_change() + clothing.get_dash_speed_change() + clothing.get_pose_speed_change() + clothing.get_attack_speed_change()
	speedAvg /= 4;
	healthAvg += clothing.get_health_change() + clothing.get_defense_change()
	healthAvg/2
	poseAvg += clothing.get_pose_hitstun_change() + clothing.get_pose_knockback_change() + clothing.get_pose_damage_change()
	poseAvg /= 3
	damageAvg += clothing.get_attack_damage_change() + clothing.get_hitstun_length_change() + clothing.get_knockback_change()
	damageAvg/3
	
	
	var changeArr = [speedAvg, healthAvg, damageAvg, poseAvg]
	return changeArr


func reset(statBar: ProgressBar, changeBar: ProgressBar):
	pass


func show_increase(changeBar: ProgressBar, amount: int):
	print("Showing increase")
	var styleBox = changeBar.get_theme_stylebox("fill").duplicate()
	styleBox.bg_color = Color.GREEN;
	changeBar.add_theme_stylebox_override("fill", styleBox)
	changeBar.value = amount


func increase_stat(statBar: ProgressBar, changeBar: ProgressBar, amount: int):
	print("Increasing stat")
	statBar.value += amount
	changeBar.value = statBar.value


func show_decrease(statBar: ProgressBar, changeBar: ProgressBar, amount: int):
	print("Showing decrease")
	var styleBox = changeBar.get_theme_stylebox("fill").duplicate()
	styleBox.bg_color = Color.YELLOW;
	changeBar.add_theme_stylebox_override("fill", styleBox)
	changeBar.value = statBar.value
	statBar.value -= amount


func decrease_stat(statBar: ProgressBar, changeBar: ProgressBar, amount: int, showing : bool = true):
	print("Decreasing stat")
	if(showing):
		changeBar.value -= amount
	else:
		statBar.value -= amount
		changeBar.value = changeBar.value


# Testing Functions
func _on_button_pressed() -> void:
	show_increase(speedChange, 10)

func _on_button_2_pressed() -> void:
	increase_stat(speedBar, speedChange, 10)

func _on_button_3_pressed() -> void:
	show_decrease(speedBar, speedChange, 10)

func _on_button_4_pressed() -> void:
	decrease_stat(speedBar, speedChange, 10)
