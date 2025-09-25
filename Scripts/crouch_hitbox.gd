class_name CrouchHitbox
extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_layer = 2
	collision_mask = 1
	self.area_entered.connect(on_area_entered)
	
	disable()

func on_area_entered(hurtbox: Hurtbox) -> void:
	if hurtbox == null: return
	
	var hurtbox_parent = hurtbox.get_parent()
	var hitbox_parent = get_parent()
	
	if (hitbox_parent == hurtbox_parent): return
	
	if "crouch_block_legal" in hurtbox_parent and hurtbox_parent.crouch_block_legal == true:
		print("Damn, they blocked!")
		hitbox_parent.attack_was_blocked(hurtbox_parent)
	elif (hitbox_parent.has_method("attack_hit")):
		print("Hitbox hit something!")
		hitbox_parent.attack_hit(hurtbox_parent)
	
	#Deal damage
	

func enable():
	visible = true
	set_process(true)
	collision_layer = 2
	collision_mask = 1
	
	set_deferred("monitoring", true) # Enable detection
	set_deferred("monitorable", true) # Enable collision

#As the name might imply, believe it or not, this disables this hitbox. Goodbye.
func disable():
	visible = false
	set_process(false)
	collision_layer = 0
	collision_mask = 0
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
