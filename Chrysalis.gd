extends KinematicBody

var parentObject
var speed : float = 2
var velocity : Vector3 = Vector3()

# all available ponies are here
onready var chrysalisElements = $Chrysalis/Armature # armature . Skeleton
onready var chrysalisAnimation =  $Chrysalis/AnimationPlayer
var splash = preload("res://levels/splashDark.tscn")
var chrysalisNodes:Dictionary = {}
var targets:Array = []
var colapseIt:float = -1
var health:int = 30


enum STATE {
	IDLE, # on ground
	RUN, # on ground
	JUMP, # from ground to air
	FLY, # in air, until on the floor
}

var chrysalisStateOld = STATE.IDLE
var chrysalisState = STATE.IDLE


func _physics_process(delta):
	# colapse = die
	if colapseIt > 0:
		if colapseIt < 1:
			colapseIt += delta
			scale = (Vector3(1,1,1)/(1+4*colapseIt))
		else:
			parentObject.removeChangelink(self)
			parentObject.endLevel()
		chrysalisAnimation.stop()
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
		
	velocity = targetVector - transform.origin + Vector3.DOWN
	velocity = velocity.normalized() * speed
	rotation.y = atan2(-velocity.z, velocity.x)
	
	var is_on_floor: bool = is_on_floor()
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# runing or gliding
	if is_on_floor: chrysalisState = STATE.RUN
	else: chrysalisState = STATE.FLY
	updateAnimation()


func updateAnimation():
	# set animation
	if(chrysalisStateOld != chrysalisState):
		chrysalisStateOld = chrysalisState
		match chrysalisState:
			STATE.IDLE: 
				chrysalisAnimation.play("idle")
			STATE.RUN:
				chrysalisAnimation.play("walk", -1, 2)
			STATE.FLY:
				chrysalisAnimation.play("fly")


func _ready():
	# init references to all children of Pony elements
	for child in chrysalisElements.get_children():
		chrysalisNodes[child.name] = child
	chrysalisAnimation.get_animation("idle").set_loop(true)
	chrysalisAnimation.get_animation("fly").set_loop(true)
	chrysalisAnimation.get_animation("run").set_loop(true)
	chrysalisAnimation.get_animation("walk").set_loop(true)
	chrysalisAnimation.play("idle")


func setParent(parent):
	parentObject = parent


func setTargets(ts:Array):
	targets = ts


func hit():
	health -=1
	if health < 0:
		colapseIt = 0.01
		parentObject.hitChangelink()


func isChangelink():
	return true


func _on_Timer_timeout():
	# cast dark magic
	var a = splash.instance()
	a.scale = Vector3(1,1,1) * 1.5
	a.start($Position3D.global_transform)
	get_parent().add_child(a)
