extends Spatial

var z:float = -10

func setZ(zz:float):
	z = zz
	transform.origin = Vector3(10 - randf() * 20, 8, z + 10 - randf() * 20)


func _process(delta):
	if z > 0:
		transform.origin += 2 * delta * Vector3.DOWN
		if transform.origin.y < -4:
			queue_free()
