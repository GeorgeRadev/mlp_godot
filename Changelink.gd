extends KinematicBody

var parentObject
var speed : float = 1
var velocity : Vector3 = Vector3()

# all available ponies are here
onready var changelinkElements = $Changelink/Armature # armature . Skeleton
onready var changelinkAnimation =  $Changelink/AnimationPlayer
var changelinkNodes:Dictionary = {}
var targets:Array = []
var colapseIt:float = -1


enum STATE {
	IDLE, # on ground
	RUN, # on ground
	JUMP, # from ground to air
	FLY, # in air, until on the floor
}

var changelinkStateOld = STATE.IDLE
var changelinkState = STATE.IDLE


func _physics_process(delta):
	# colapse = die
	if colapseIt > 0:
		if colapseIt < 1:
			colapseIt += delta
			scale = (Vector3(1,1,1)/(1+4*colapseIt))
		else:
			parentObject.removeChangelink(self)
		changelinkAnimation.stop()
		return
	
	# check targets
	if typeof(targets) != TYPE_ARRAY and len(targets) <= 0:
		return
	
	#find the nearest target
	var targetDistance = 500
	var targetVector = targets[0]
	for i in range(len(targets)-1):
		var vector = targets[i]
		if vector != null and typeof(vector) == TYPE_VECTOR3:
			var distance = transform.origin.distance_to(vector)
			if targetDistance > distance:
				targetDistance = distance
				targetVector = vector
		
	velocity = targetVector - transform.origin
	velocity = velocity.normalized() * speed
	rotation.y = atan2(-velocity.z, velocity.x)
	
	var is_on_floor: bool = is_on_floor()
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# runing or gliding
	if is_on_floor: changelinkState = STATE.RUN
	else: changelinkState = STATE.FLY
	updateAnimation()


func updateAnimation():
	# set animation
	if(changelinkStateOld != changelinkState):
		changelinkStateOld = changelinkState
		match changelinkState:
			STATE.IDLE: 
				changelinkAnimation.play("idle")
			STATE.RUN:
				changelinkAnimation.play("run", -1, 2)
			STATE.FLY:
				changelinkAnimation.play("fly")


func _ready():
	# init references to all children of Pony elements
	for child in changelinkElements.get_children():
		changelinkNodes[child.name] = child
	changelinkAnimation.get_animation("idle").set_loop(true)
	changelinkAnimation.get_animation("fly").set_loop(true)
	changelinkAnimation.get_animation("run").set_loop(true)
	changelinkAnimation.play("idle")
	
	var eye_color:int = Color.from_hsv(randf(), 0.8, 0.8, 1.0).to_rgba32()
	showBody(eye_color)


func apply_texture(mesh_instance_node, texture_path):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(0xffffffff)
	mesh_instance_node.set_material_override(material)
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load(texture_path)
	texture.create_from_image(image)
	if mesh_instance_node.material_override:
		mesh_instance_node.material_override.albedo_texture = texture  

func showBody(eyes_color:int):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(eyes_color)
	changelinkNodes['eyes'].set_material_override(material)


func setParent(parent):
	parentObject = parent


func setTargets(ts:Array):
	targets = ts

func colapse():
	if colapseIt < 0:
		colapseIt = 0.01
		parentObject.hitChangelink()
	

func isChangelink():
	return true
