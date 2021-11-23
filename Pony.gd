extends KinematicBody

export(String, "p1", "p2", "p3", "p4") var key_prefix

var gravity : Vector3 = Vector3.DOWN * 14
var speed : float = 4
var jump_speed : float = 6
var fly_speed : float = 1.5
var velocity : Vector3 = Vector3()
var can_move: bool = true

# all available ponies are here
var ponyTypeOld : int = -1
export var ponyType : int = 0
var ponyTypes: Array = []
onready var ponyElements = $Pony/Armature # armature . Skeleton
onready var ponyAnimation: AnimationPlayer  =  $Pony/AnimationPlayer
var ponyNodes: Dictionary = {}
var hasWings: bool = false
var hasHorn: bool = false
var old_on_floor: bool = false
var magicColor:int = 0

enum STATE {
	IDLE, # on ground
	RUN, # on ground
	PUSH, # on ground
	JUMP, # from ground to air
	FALL, # in air, until on the floor
	FLY, # in air, until on the floor
	GLIDE # in air, until on the floor
}

var playerStateOld = STATE.IDLE
var playerState = STATE.IDLE


onready var audio_run:AudioStreamPlayer = $run
onready var audio_jump:AudioStreamPlayer = $jump
var ponyNames: Array = []
var delayPonyName:bool = true

var magic = preload("res://levels/magic.tscn")
var splash = preload("res://levels/splash.tscn")

func _process(_delta):
	# selecting different pony
	if Input.is_action_just_pressed(key_prefix +"_select") :
		ponyType = ( ponyType + 1 ) % len(ponyTypes)
	#apply pony
	if ponyTypeOld != ponyType:
		ponyTypeOld = ponyType
		ponyTypes[ponyType].call_func()
		if ponyType < len(ponyNames):
			var time = 2*(ponyType) if delayPonyName else 0
			yield(get_tree().create_timer(time), "timeout")
			ponyNames[ponyType].play()
			delayPonyName = false
	


func _physics_process(delta):
		
	# falling or gliding
	if playerState == STATE.GLIDE:
		velocity += (gravity / 8) * delta
	else: # on the ground or fall
		velocity += gravity * delta
	
	if can_move:
		# keep  gravity
		var velocity_y = velocity.y
		velocity = Vector3.ZERO
		velocity.z = 0
		if Input.is_action_pressed(key_prefix +"_up"):
			velocity.z = 1
		if Input.is_action_pressed(key_prefix +"_down"):
			velocity.z = -1
		if Input.is_action_pressed(key_prefix +"_left"):
			velocity.x = 1
		if Input.is_action_pressed(key_prefix +"_right"):
			velocity.x = -1
		velocity = velocity.normalized() * speed
		# restore gravity
		velocity.y = velocity_y
	
	# move player
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if !can_move:
		playerState = STATE.IDLE
		updateAnimation()
		return
	
	var is_on_floor: bool = is_on_floor()
	var moving: bool = abs(velocity.x) > 0.2 or abs(velocity.z) > 0.2
	var push_pressed: bool = Input.is_action_just_pressed(key_prefix + "_A")	
	var push_hold: bool = Input.is_action_pressed(key_prefix + "_A")
	var jump_pressed: bool = Input.is_action_just_pressed(key_prefix + "_B")
	var jump_hold: bool = Input.is_action_pressed(key_prefix + "_B")

	#rotate player
	if moving: rotation.y = atan2(-velocity.z, velocity.x)

	if is_on_floor: #ground
		if playerState != STATE.PUSH: 
			if moving:
				playerState = STATE.RUN
			else:
				playerState = STATE.IDLE
		if push_pressed:
			# if has horn or rainbawdash make rainbow
			if hasHorn or ponyType == 5:
				var a = splash.instance()
				a.start($Position3D.global_transform)
				get_parent().add_child(a)
				$magic.play()
			else:
				var a = magic.instance()
				var material = SpatialMaterial.new()
				material.albedo_color = Color(magicColor)
				a.get_child(0).set_material_override(material)
				a.start($Position3D.global_transform)
				get_parent().add_child(a)
				$magic.play()
		if push_hold: 
			playerState = STATE.PUSH
		if jump_pressed:
			velocity.y = jump_speed
			playerState = STATE.JUMP
			audio_jump.play(0)

	elif hasWings: # in air flying behaviour
		if jump_pressed :
			velocity.y = fly_speed
			playerState = STATE.FLY
		elif jump_hold and (playerState == STATE.FALL or playerState == STATE.FLY):
			playerState = STATE.GLIDE
		elif not jump_hold:
			playerState = STATE.FALL
	
	updateAnimation()


func action_spike():
	velocity *= -1
	velocity.y = jump_speed
	can_move = false
	yield(get_tree().create_timer(1), "timeout")
	can_move = true

func action_cristal():
	velocity *= -1
	velocity.y = jump_speed
	can_move = false
	$cristal.visible = true
	yield(get_tree().create_timer(0.5), "timeout")
	velocity *= 0
	velocity.y = 0
	yield(get_tree().create_timer(5), "timeout")
	decristalize()
	
func decristalize():
	$cristal.visible = false
	can_move = true
	

func action_trampoline(v: Vector3):
	velocity = v
	
func action_heart():
	$ching.play()

func updateAnimation():
	if !can_move:
		ponyAnimation.play("push")
		ponyAnimation.seek(0.1,true)
		ponyAnimation.stop(false)
		return
	# set animation
	if(playerStateOld != playerState):
		playerStateOld = playerState
		#print(key_prefix + " " + str(playerState))
		match playerState:
			STATE.IDLE: 
				ponyAnimation.play("idle")
				if audio_run.is_playing():
					audio_run.stop()
			STATE.RUN:
				ponyAnimation.play("run", -1, 3)
				if ! audio_run.is_playing():
					var stream:AudioStreamOGGVorbis = audio_run.stream
					stream.loop = true
					audio_run.play()
			STATE.PUSH:
				ponyAnimation.play("push")
			STATE.JUMP:
				ponyAnimation.play("jump")
			STATE.FALL:
				ponyAnimation.play("fall")
			STATE.FLY:
				ponyAnimation.play("fly")
			STATE.GLIDE:
				ponyAnimation.play("glide")


func animation_finished(anim_name : String):
	if "fly" == anim_name:
		playerState = STATE.GLIDE
	elif "jump" == anim_name:
		playerState = STATE.FALL
	else:
		playerState = STATE.IDLE
	updateAnimation()


func _ready():
	# init references to all children of Pony elements
	for child in ponyElements.get_children():
		ponyNodes[child.name] = child
	ponyTypes.append(funcref(self,"showTwilightSparkle"))
	ponyTypes.append(funcref(self,"showFlutterShy"))
	ponyTypes.append(funcref(self,"showAppleJack"))
	ponyTypes.append(funcref(self,"showRarity"))
	ponyTypes.append(funcref(self,"showPinkeyPie"))
	ponyTypes.append(funcref(self,"showRainbowDash"))
	ponyTypes.append(funcref(self,"showSunsetShimmer"))
	ponyTypes.append(funcref(self,"showTrixy"))
	ponyTypes.append(funcref(self,"showRandom"))
	
	var __ = ponyAnimation.connect("animation_finished", self, "animation_finished")
	ponyAnimation.get_animation("idle").set_loop(true)
	ponyAnimation.get_animation("walk").set_loop(true)
	ponyAnimation.get_animation("run").set_loop(true)
	ponyAnimation.get_animation("glide").set_loop(true)
	ponyAnimation.get_animation("fall").set_loop(true)
	ponyAnimation.get_animation("hover").set_loop(true)
	ponyAnimation.play("idle")
	playerState = STATE.IDLE
	
	ponyNames.append($PlayerName1)
	ponyNames.append($PlayerName2)
	ponyNames.append($PlayerName3)
	ponyNames.append($PlayerName4)
	ponyNames.append($PlayerName5)
	ponyNames.append($PlayerName6)


func hidePonyElements():
	for child in ponyElements.get_children():
		child.visible = false
	$cristal.visible = false

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

func showBody(color:int, wings:bool, horn:bool):
	hidePonyElements()
	var material = SpatialMaterial.new()
	material.albedo_color = Color(color)
	ponyNodes['body'].set_material_override(material)
	ponyNodes['horn'].set_material_override(material)
	ponyNodes['wingl 2'].set_material_override(material)
	ponyNodes['wingr 2'].set_material_override(material)
	ponyNodes['body'].visible = true
	ponyNodes['eyes'].visible = true
	ponyNodes['teetdown'].visible = true
	ponyNodes['teethup'].visible = true
	ponyNodes['tongh'].visible = true
	if wings:
		ponyNodes['wingl 2'].visible = true
		ponyNodes['wingr 2'].visible = true
	hasWings = wings
	if horn:
		ponyNodes['horn'].visible = true
	hasHorn = horn


func showTwilightSparkle():
	magicColor = 0xe3b1faff
	showBody(magicColor, true, true)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_twilight.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_pink.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['tshair'].visible = true
	ponyNodes['tsmane'].visible = true
	ponyNodes['tstail'].visible = true
	ponyNodes['eyelashesup1'].visible = true
	
func showPinkeyPie():
	magicColor = 0xf4c4dcff
	showBody(magicColor, false, false)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_pinkie_pie.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_blue.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['pphair'].visible = true
	ponyNodes['pptail'].visible = true
	ponyNodes['eyelashesup1'].visible = true
	ponyNodes['eyelashesdown1'].visible = true

func showRainbowDash():
	magicColor = 0x98e2ffff
	showBody(magicColor, true, false)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_rainbow_dash.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_pink.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['rdhair'].visible = true
	ponyNodes['rdtail'].visible = true
	ponyNodes['eyelashesup2'].visible = true
	ponyNodes['eyelashesdown2'].visible = true

func showAppleJack():
	magicColor = 0xffc360ff
	showBody(magicColor, false, false)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_applejack.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_green.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['ajhair'].visible = true
	ponyNodes['ajtail'].visible = true
	ponyNodes['ajhat'].visible = true
	ponyNodes['eyelashesup1'].visible = true
	ponyNodes['eyelashesdown1'].visible = true

func showFlutterShy():
	magicColor = 0xfff4a3ff
	showBody(magicColor, true, false)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_fluttershy.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_blue_light.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['fshair'].visible = true
	ponyNodes['fsmane'].visible = true
	ponyNodes['fstail'].visible = true
	ponyNodes['eyelashesdown1'].visible = true
	ponyNodes['eyelashesdown2'].visible = true

func showRarity():
	magicColor = 0xecf0f4ff
	showBody(magicColor, false, true)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_rarity.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_blue.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['rrhair'].visible = true
	ponyNodes['rrmane'].visible = true
	ponyNodes['rrtail'].visible = true
	ponyNodes['eyelashesup1'].visible = true
	ponyNodes['eyelashesup2'].visible = true
	ponyNodes['eyelashesdown1'].visible = true
	ponyNodes['eyelashesdown2'].visible = true

func showSunsetShimmer():
	magicColor = 0xf89f2bff
	showBody(magicColor, false, true)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_sunset_shimmer.png")
	apply_texture(ponyNodes['eyes'], "res://PonyEyes/eyes_pink.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['sshair'].visible = true
	ponyNodes['ssmane'].visible = true
	ponyNodes['sstail'].visible = true
	ponyNodes['eyelashesup2'].visible = true
	ponyNodes['eyelashesdown2'].visible = true

func showTrixy():
	magicColor = 0x55acf3ff
	showBody(magicColor, false, true)
	apply_texture(ponyNodes['cutiemark'], "res://PonyCutieMarks/cutie_trixie.png")
	ponyNodes['cutiemark'].visible = true
	ponyNodes['tcoin'].visible = true
	ponyNodes['that'].visible = false
	ponyNodes['tkape'].visible = true
	ponyNodes['thair'].visible = true
	ponyNodes['tmane'].visible = true
	ponyNodes['ttail'].visible = true
	ponyNodes['eyelashesup1'].visible = true
	ponyNodes['eyelashesdown1'].visible = true

func showRandom():
	ponyNodes['cutiemark'].visible = false
	var color:int = Color.from_hsv(randf(), 0.30, 0.90, 1.0).to_rgba32()
	magicColor = color
	showBody(color, randi() % 2 == 0, randi() % 2 == 0)
	var choice = str(1+(randi() % 3))
	var hair = 'hair'+choice
	var mane = 'mane'+choice
	var tail = 'tail'+choice
	var material = SpatialMaterial.new()
	material.albedo_color = Color.from_hsv(randf(), 0.88, 0.88, 1.0)
	ponyNodes[hair].set_material_override(material)
	ponyNodes[mane].set_material_override(material)
	ponyNodes[tail].set_material_override(material)
	ponyNodes[hair].visible = true
	ponyNodes[mane].visible = true
	ponyNodes[tail].visible = true
	if randi() % 2 == 0:
		ponyNodes['eyelashesup'+str(1+(randi() % 2))].visible = true
	if randi() % 2 == 0:
		ponyNodes['eyelashesdown'+str(1+(randi() % 2))].visible = true


func isPony():
	return true
