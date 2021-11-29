extends Spatial

var PLAYERS = 2

var worldZ: float = 0
var players:Array = []
var playersCoordinates:Array = []
var changelinks:Array = []

onready var camera:Camera = $_Camera

var levelContainer:Spatial = null
var theBOX:Spatial = null
var ponyClass = preload("res://Pony.tscn")
var changelinkClass = preload("res://Changelink.tscn")

var TheBOX = preload("res://levels/TheBOX.tscn")
var levelElements: Array = []


const SEGMENT_LENGTH:int = 20
var Spring:Array = [
	preload("res://levels/springStart.tscn"),
	preload("res://levels/springEnd.tscn"),
	preload("res://levels/spring0.tscn"),
	preload("res://levels/spring1.tscn"),
	preload("res://levels/spring2.tscn"),
	preload("res://levels/spring3.tscn"),
]
var Summer:Array = [
	preload("res://levels/summerStart.tscn"),
	preload("res://levels/summerEnd.tscn"),
	preload("res://levels/summer0.tscn"),
	preload("res://levels/summer1.tscn"),
	preload("res://levels/summer2.tscn"),
	preload("res://levels/summer3.tscn"),
]
var Fall:Array = [
	preload("res://levels/fallStart.tscn"),
	preload("res://levels/fallEnd.tscn"),
	preload("res://levels/fall0.tscn"),
	preload("res://levels/fall1.tscn"),
	preload("res://levels/fall2.tscn"),
]
var Winter:Array = [
	preload("res://levels/winterStart.tscn"),
	preload("res://levels/winterEnd.tscn"),
	preload("res://levels/winter0.tscn"),
	preload("res://levels/winter1.tscn"),
	preload("res://levels/winter2.tscn"),
]
var snowflake = preload("res://levels/snowflake.tscn")
const SeasonStart:int = 0
const SeasonEnd:int = 1
var Seasons:Array = [ Fall, Summer, Spring, Winter]
var SeasonCurrent:int = -1

func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resetLevel()


var max_level_length:int = 20
func generateRandomSegment(z:int):
	if z > max_level_length:
		return
	var currentSeason:Array = Seasons[SeasonCurrent]
	var object 
	if z == max_level_length:
		object = currentSeason[SeasonEnd].instance()
	else:
		object = currentSeason[SeasonEnd + 1 + randi() % (len(currentSeason) - 2)].instance()
	object.translate(Vector3(0, 0, z * SEGMENT_LENGTH))
	levelContainer.add_child(object)
	levelElements.append(object)


func generateRandomLevel():
	var object
	if len(levelElements) <= 0:
		#create level start
		object = Seasons[SeasonCurrent][SeasonStart].instance()
		object.translate(Vector3.ZERO)
		levelContainer.add_child(object)
		levelElements.append(object)
	var currentElementZ = int((theBOX.transform.origin.z  - 0.48)/ 20)
	# add level segments
	for _i in range(len(levelElements), currentElementZ + 5):
		generateRandomSegment(len(levelElements))
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
	#move to next season
	SeasonCurrent += 1
	SeasonCurrent = SeasonCurrent % len(Seasons)
	#create random level
	generateRandomLevel()
	# add players
	var arrayTypes:Array=[]
	if len(players) <= 0:
		for player in range(PLAYERS):
			arrayTypes.append(player)
			playersCoordinates.append(null)
	else:
		for player in players:
			arrayTypes.append(player.ponyType);
	players.clear()
	for player in range(PLAYERS):
		object = ponyClass.instance()
		levelContainer.add_child(object)
		players.append(object)
		object.translate(Vector3( 1.5 - 1*player, 2, 0))
		object.rotate_y(PI/2)
		object.ponyType = arrayTypes[player]
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
	#var yspan = abs(y_max - y_min)
	camera.transform.origin = Vector3(medianx, 2.5 + max(xspan/2.6, y_max-1), z_min-3)
	if z_min+3 > theBOX.transform.origin.z:
		theBOX.transform.origin.z =  z_min+3
		generateRandomLevel()
	
	if SeasonCurrent == 3:
		#generate snow if needed
		var object = snowflake.instance()
		object.setZ(z_max)
		levelContainer.add_child(object)
	
	if z_max > max_level_length * SEGMENT_LENGTH:
		resetLevel()

 
func _process(_delta):
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
	object.translate(Vector3( 8 - 16 * randf(), 3, theBOX.transform.origin.z + 6))
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
