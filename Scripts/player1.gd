extends BaseCharacterController

signal one_died


#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	player_type = 1
	enemy_name = "Player2"
	healthbar = $"../Healthbar"
	super.scale_stats()
	healthbar.init_health(health)
	super._ready()

func report_dead():
	#HEEERE!
	SfxManager.playDeath()
	one_died.emit()
	pass
