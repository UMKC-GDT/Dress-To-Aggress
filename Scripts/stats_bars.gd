extends Node2D

var healthStat: int = 50
var speedStat: int = 50
var poseStat: int = 50
var damageStat: int = 50

var lastHealthChange
var lastSpeedChange
var lastPoseChange
var lastDamageChange

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
	match(toDo):
		0: # shows change for all bars
			print("showing change")
			var changeArr = getAverageStatChange(clickedObj)
			# finds actual amount to increase/decrease
			var speedDif = speedBar.value * changeArr[0]
			var healthDif = healthBar.value * changeArr[1]
			var damageDif = damageBar.value * changeArr[2]
			var poseDif = poseBar.value * changeArr[3]
			
			showChange(healthBar, healthChange, healthDif)
			showChange(speedBar, speedChange, speedDif)
			showChange(damageBar, damageChange, damageDif)
			showChange(poseBar, poseChange, poseDif)
			lastHealthChange = healthDif
			lastSpeedChange = speedDif
			lastDamageChange = damageDif
			lastPoseChange = poseDif
		1: # changes all bars + all the stats if resetBars() is called at some point
			print("commiting change")
			commitChange(healthBar, healthChange, lastHealthChange)
			commitChange(speedBar, speedChange, lastSpeedChange)
			commitChange(damageBar, damageChange, lastDamageChange)
			commitChange(poseBar, poseChange, lastPoseChange)
		
			speedStat += lastSpeedChange
			healthStat += lastHealthChange
			damageStat += lastDamageChange
			poseStat += lastPoseChange
		2: # undos changes caused above when clothes are taken off
			print("Undoing")
			speedStat += lastSpeedChange * -1
			healthStat += lastHealthChange * -1
			damageStat += lastDamageChange * -1
			poseStat += lastPoseChange * -1
			resetBars()
		3:
			print("resetting")
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
	speedAvg = global.roundFloat(speedAvg / 4, 2)
	healthAvg += clothing.get_health_change() + clothing.get_defense_change()
	healthAvg = global.roundFloat( healthAvg / 2, 2)
	poseAvg += clothing.get_pose_hitstun_change() + clothing.get_pose_knockback_change() + clothing.get_pose_damage_change()
	poseAvg = global.roundFloat(poseAvg / 3, 2)
	damageAvg += clothing.get_attack_damage_change() + clothing.get_hitstun_length_change() + clothing.get_knockback_change()
	damageAvg = global.roundFloat(damageAvg / 3, 2)
	
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
		changeBar.value = statBar.value
	else:
		statBar.value += dif
		changeBar.value = statBar.value


func undoChange(statBar: ProgressBar, changeBar: ProgressBar, dif: int) -> void:
	print(dif)
	dif *= -1
	print(dif)
	statBar.value += dif
	changeBar.value = statBar.value


func resetBars():
	healthBar.value = healthStat
	healthChange.value = healthStat
	speedBar.value = speedStat
	speedChange.value = speedStat
	damageBar.value = damageStat
	damageChange.value = damageStat
	poseBar.value = poseStat
	poseChange.value = poseStat
