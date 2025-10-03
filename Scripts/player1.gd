extends BaseCharacterController

signal one_died

#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	var currScene = get_tree().get_current_scene()
	
	if currScene.name == "Tutorial Level":
		healthbar = $"/root/Tutorial Level/CanvasLayer/Healthbar"
		enemy_name = "Dummy"
	else:
		healthbar = $"/root/Test Level/CanvasLayer/Healthbar"
		enemy_name = "Player2"
		
	player_type = 1
	print(currScene.name)
	super.scale_stats()
	healthbar.init_health(health)
	super._ready()

func report_dead():
	#HEEERE!
	SfxManager.playDeath()
	one_died.emit()
	pass
