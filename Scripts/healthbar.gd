extends ProgressBar


@onready var timer = $Timer
@onready var damage_bar = $DamageBar

var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0:
		print("Healthbar's empty!")
	
	if health < prev_health:
		timer.start()
	else:
		$DamageBar.value = health

func init_health(_health):
	max_value = _health
	health = _health
	value = health
	
	print(health)
	print(max_value)
	print(value)
	
	$DamageBar.max_value = health
	$DamageBar.value = health

func _on_timer_timeout() -> void:
	$DamageBar.value = health
