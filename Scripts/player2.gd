extends BaseCharacterController

#WARNING!!!!!!! If you get weird errors, >WARNING< MAKE SURE THAT THE ENEMY NAME IS EXACT TO THE NODE IN THE LEVEL >WARNING<. Check this in case of any weird null errors.
func _ready():
	player_type = 2
	enemy_name = "Player"
	super._ready()
