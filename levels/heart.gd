extends Area

func _on_heart_body_entered(body):
	if body.has_method("action_heart"):
		queue_free()
		body.action_heart()
