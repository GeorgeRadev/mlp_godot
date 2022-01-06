extends Area


func start(tf: Transform):
	transform.origin = tf.origin
	var material = SpatialMaterial.new()
	material.albedo_color = Color(0x17877aff)
	$splash/Armature/Skeleton/Cylinder.set_material_override(material)
	$splash/AnimationPlayer.play("splash")


func _process(_delta):
	$splash/AnimationPlayer.play("splash")


func _on_Timer_timeout():
	queue_free()


func _on_splash_body_entered(body):
	if body.has_method("action_cristal"):
		body.action_cristal()
