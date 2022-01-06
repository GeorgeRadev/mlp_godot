extends Spatial

var leafColor:Array = [0xe79831ff, 0xE8E531ff, 0xE3814Fff]
onready var leaf = $leaf
var fallspeed:float = 10
var start:float

func _ready():
	var material = SpatialMaterial.new()
	var color = leafColor[ randi() % len(leafColor)]
	material.albedo_color = Color(color)
	leaf.set_material_override(material)
	start = 30 * randf()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if start > 0:
		start -= delta
	else:
		# fall
		if leaf.global_transform.origin.y > 0.1:
			leaf.transform.origin.y -= delta * fallspeed
