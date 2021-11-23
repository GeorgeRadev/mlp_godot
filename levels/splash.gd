extends Area


func start(tf: Transform):
	transform.origin = tf.origin
	$splash/AnimationPlayer.play("splash")


func _process(_delta):
	$splash/AnimationPlayer.play("splash")


func _on_Timer_timeout():
	queue_free()


func _on_splash_body_entered(body):
	if body.has_method("isChangelink"):
		body.colapse()
