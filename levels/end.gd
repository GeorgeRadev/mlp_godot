extends Spatial

func _ready():
	$splash1/AnimationPlayer.get_animation("splash").loop = true
	$splash1/AnimationPlayer.play("splash", -1, 1.3)
