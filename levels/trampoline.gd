extends Area

export(Vector3) var velocity

func _on_Trampoline_body_entered(body):
	if body.has_method("action_trampoline"):
		$wohoo.play()
		body.action_trampoline(velocity)
