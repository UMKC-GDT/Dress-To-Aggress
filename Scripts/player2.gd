extends BaseCharacterController

#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	var currScene = get_tree().get_current_scene()
	if currScene.name == "Tutorial Level":
		healthbar = $"/root/Tutorial Level/CanvasLayer/Healthbar"
		enemy_name = "Player"
	else:
		healthbar = $"/root/Test Level/CanvasLayer/Healthbar"
		enemy_name = "Player"
	
	player_type = 2
	super.scale_stats()
	healthbar.init_health(health)
	super._ready()
