extends Area

func _on_Cristal_body_entered(body):
	if body.has_method("action_cristal"):
		body.action_cristal()
