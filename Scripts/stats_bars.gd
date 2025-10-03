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
	resetBars()


func updateStatsBars(clickedObj, toDo) -> void:
	var changeArr = getAverageStatChange(clickedObj)
	
	#print("Average speed change " + str(changeArr[0]))
	#print("Average health change " + str(changeArr[1]))
	#print("Average damage change " + str(changeArr[2]))
	#print("Average pose change " + str(changeArr[3]))
	
	# finds actual amount to increase/decrease
	var speedDif = speedBar.value * changeArr[0]
	var healthDif = healthBar.value * changeArr[1]
	var damageDif = damageBar.value * changeArr[2]
	var poseDif = poseBar.value * changeArr[3]
	
	
	match(toDo):
		0: # shows change for all bars
			showChange(healthBar, healthChange, speedDif)
			showChange(speedBar, speedChange, healthDif)
			showChange(damageBar, damageChange, damageDif)
			showChange(poseBar, poseChange, poseDif)
		1: # changes all bars + all the stats if resetBars() is called at some point
			commitChange(healthBar, healthChange, speedDif)
			commitChange(speedBar, speedChange, healthDif)
			commitChange(damageBar, damageChange, damageDif)
			commitChange(poseBar, poseChange, poseDif)
			speedStat += speedDif
			healthStat += healthDif
			damageStat += damageDif
			poseStat += poseDif
		2: # undos changes caused above when clothes are taken off
			resetBars()
		3:
			resetBars()
		_:
			print(toDo, " Entered. Expected 0-3")


func getAverageStatChange(clickedObj) -> Array:
	var clothing = clickedObj.current_wearable # gets clothings stats
	var speedAvg = 0
	var healthAvg = 0
	var poseAvg = 0
	var damageAvg = 0
	
	# averages changes to stats, could be changed because some result in 0 when there are noticable differences
	speedAvg += clothing.get_walk_speed_change() + clothing.get_dash_speed_change() + clothing.get_pose_speed_change() + clothing.get_attack_speed_change()
	speedAvg /= 4;
	healthAvg += clothing.get_health_change() + clothing.get_defense_change()
	healthAvg/2
	poseAvg += clothing.get_pose_hitstun_change() + clothing.get_pose_knockback_change() + clothing.get_pose_damage_change()
	poseAvg /= 3
	damageAvg += clothing.get_attack_damage_change() + clothing.get_hitstun_length_change() + clothing.get_knockback_change()
	damageAvg/3
	
	return [speedAvg, healthAvg, damageAvg, poseAvg]


func showChange(statBar: ProgressBar, changeBar: ProgressBar, dif: int) -> void:
	if dif < 0: # if it's a decrease
		#print("Showing decrease")
		# creates new theme with color yellow to give to the bar
		# this prevents them all from changing color
		var styleBox = changeBar.get_theme_stylebox("fill").duplicate()
		styleBox.bg_color = Color.YELLOW;
		changeBar.add_theme_stylebox_override("fill", styleBox)
		changeBar.value = statBar.value
		statBar.value += dif
	else: # if its an increase
		#print("Showing increase")
		var styleBox = changeBar.get_theme_stylebox("fill").duplicate()
		styleBox.bg_color = Color.GREEN;
		changeBar.add_theme_stylebox_override("fill", styleBox)
		changeBar.value += dif


func commitChange(statBar: ProgressBar, changeBar: ProgressBar, dif: int) -> void:
	if dif < 0:
		#print("Increasing stat")
		statBar.value += dif
		changeBar.value = statBar.value
	else:
		#print("Decreasing stat")
		changeBar.value = statBar.value


func undoChange(statBar: ProgressBar, changeBar: ProgressBar, dif: int) -> void:
	dif *= -1
	statBar.value += dif
	changeBar.value = statBar.value


func resetBars():
	healthBar.value = healthStat
	healthChange.value = healthBar.value
	speedBar.value = speedStat
	speedChange.value = healthChange.value
	damageBar.value = damageStat
	damageChange.value = damageBar.value
	poseBar.value = poseStat
	poseChange.value = poseBar.value
