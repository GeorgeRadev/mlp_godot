extends Area

func _on_heart_body_entered(body):
	queue_free()
	if body.has_method("action_heart"):
		body.action_heart()
