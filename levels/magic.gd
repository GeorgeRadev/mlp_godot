extends Area

var speed = 8
var velocity:Vector3


func start(tf):
	transform = tf
	velocity = transform.basis.z * speed


func _process(delta):
	transform.origin += velocity * delta


func _on_Timer_timeout():
	queue_free()


func _on_magic_body_entered(body):
	if body.has_method("isPony"):
		pass
	elif body.has_method("isChangelink"):
		body.colapse()
	elif body is StaticBody:
		queue_free()
