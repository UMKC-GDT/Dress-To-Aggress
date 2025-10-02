extends CanvasLayer
func transition():
	$AnimationPlayer.play("fade_to_black")
	$AnimationPlayer.play("fade_to_normal")
