extends Area

func _on_Spike_body_entered(body):
	if body.has_method("action_spike"):
		$hurts.play()
		body.action_spike()
