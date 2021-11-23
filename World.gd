extends Spatial

var PLAYERS = 2

var players:Array = [null, null, null, null]
var changelinks:Array = []
var playersCoordinates:Array = [null, null, null, null]
var worldZ: float = 0

onready var camera:Camera = $_Camera

var levelContainer:Spatial = null
var theBOX:Spatial = null
var ponyClass = preload("res://Pony.tscn")
var changelinkClass = preload("res://Changelink.tscn")

var TheBOX = preload("res://levels/TheBOX.tscn")
var levelElements: Array = []

var start = preload("res://levels/start.tscn")
var green0 = preload("res://levels/green0.tscn")
var green1 = preload("res://levels/green1.tscn")
var green2 = preload("res://levels/green2.tscn")
var green3 = preload("res://levels/green3.tscn")
var segments:Array = [green0, green1, green2, green3]

func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resetLevel()


func generateRandomSegment(z:float):
	var object = segments[randi() % len(segments)].instance()
	object.translate(Vector3(0,0, z))
	levelContainer.add_child(object)
	levelElements.append(object)


func generateRandomLevel():
	var object
	if len(levelElements) <= 0:
		#create level start
		object = start.instance()
		object.translate(Vector3.ZERO)
		levelContainer.add_child(object)
		levelElements.append(object)
	var currentElementZ = int((theBOX.transform.origin.z  - 0.48)/ 20)
	# add level segments
	while len(levelElements) < currentElementZ + 5:
		generateRandomSegment(20*len(levelElements))
	# delete invisible segments
	currentElementZ -= 2
	while currentElementZ >= 0 and levelElements[currentElementZ] != null:
		object = levelElements[currentElementZ]
		levelElements[currentElementZ] = null
		levelContainer.remove_child(object)
		object.queue_free()
		currentElementZ -= 1


func resetLevel():
	var oldLevelContainer = levelContainer
	levelElements = []
	# create level object container
	levelContainer = Spatial.new()
	add_child(levelContainer)
	var object
	# create running BOX
	object = TheBOX.instance()
	object.translate(Vector3.ZERO)
	levelContainer.add_child(object)
	theBOX = object
	#create random level
	generateRandomLevel()
	# add players
	players.clear()
	for player in range(PLAYERS):
		object = ponyClass.instance()
		levelContainer.add_child(object)
		players.append(object)
		object.translate(Vector3( 1.5 - 1*player, 2, 0))
		object.rotate_y(PI/2)
		object.ponyType = player
		object.key_prefix = "p"+str(player+1)
	# delete all level elements
	if oldLevelContainer != null:
		remove_child(oldLevelContainer)
		oldLevelContainer.queue_free()

func setCamera():
	var p:Vector3 = players[0].transform.origin
	var x_min: float = p.x
	var x_max: float = p.x
	var y_min: float = p.y
	var y_max: float = p.y
	var z_min: float = p.z
	var z_max: float = p.z
	var ix = 0
	for player in players:
		p = player.transform.origin
		playersCoordinates[ix] = p
		ix += 1
		x_min = min(x_min, p.x)
		x_max = max(x_max, p.x)
		y_min = min(y_min, p.y)
		y_max = max(y_max, p.y)
		z_min = min(z_min, p.z)
		z_max = max(z_max, p.z)
	var medianx = (x_min + x_max) / 2.0
	var xspan = abs(x_max - x_min)
	var yspan = abs(y_max - y_min)
	camera.transform.origin = Vector3(medianx, 2.5 + max(xspan/2.6, y_max-1), z_min-3)
	if z_min+3 > theBOX.transform.origin.z:
		theBOX.transform.origin.z =  z_min+3
		generateRandomLevel()


func _process(delta):
	if Input.is_action_just_pressed("ui_select"):
		resetLevel()
		
	elif Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	elif Input.is_action_just_pressed("create_changelink"):
		_on_Timer_timeout()
	
	# send coodinates to changelinks
	for changelink in changelinks:
		changelink.setTargets(playersCoordinates)

	# move camera to see all players
	setCamera()


func _on_Timer_timeout():
	addChangelink()


var changelinkSpawnCount:int = 0

func addChangelink():
	var object = changelinkClass.instance()
	object.setParent(self)
	object.translate(Vector3( 16 * (randf() -0.5), 3, theBOX.transform.origin.z + 6))
	changelinkSpawnCount += 1
	if changelinkSpawnCount >= 5:
		changelinkSpawnCount = 0
		object.scale = Vector3(2,2,2)
	add_child(object)
	changelinks.append(object)
	$changelink.play()

func hitChangelink():
	if randi() % 2 == 1:
		$greatJob.play()
	else:
		$thebest.play()

func removeChangelink(changelink):
	changelinks.remove(changelinks.find(changelink))
	changelink.queue_free()
