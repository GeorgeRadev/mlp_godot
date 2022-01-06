extends Spatial


func _ready():
	$Portal.visible = false


func openPortal():
	$Portal.visible = true
	$Portal/AnimationPlayer.get_animation("splash").loop = true
	$Portal/AnimationPlayer.play("splash", -1, 1.3)
