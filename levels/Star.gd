extends Area


func _on_Star_body_entered(body):
	if body.has_method("action_boost"):
		queue_free()
		body.action_boost()
