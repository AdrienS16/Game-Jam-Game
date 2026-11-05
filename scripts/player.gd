class_name Player extends CharacterBody2D

@onready var spawn: Node2D = $"../Spawn"

@export var gravity := 350.0
@export var speed := 75.0
@export var jump_speed := 160.0
@export var wall_jump_speed := 80.0
@export var wall_slide_speed := 50.0;
@export var grapple_final_velocity := 175.0
@export var grapple_initial_velocity := 50.0
@export var grapple_max_reach := 75
@export var max_health := 100
@export var checkpos1: float
@export var checkpos2: float
@export var pushforce = 100
#The y value of what's considered "out of bounds" - to be changed with level design
@export var floorbound := 150

var facing_right = true
var interacting = false

enum Stage
{
	GROUND,
	JUMP,
	FALL,
	WALL,
	WALLJUMP,
	GRAPPLE
}

var currentStage = Stage.FALL
var lastStage
var wallNormal

var input
var lastInput
var inputDirty

var canGrapple = false
var grappleTarget
var grappleStart

var potentialGrappleLight: Node2D = null

signal health_changed(new_health: int)
var health := max_health
var drain_timer := 0.0

var audioTimerWalk = 0

var currentAnimOffset: float

func _ready() -> void:
	checkpos1 = spawn.position.x
	checkpos2 = spawn.position.y

func _process(delta: float) -> void:
	drain_timer += delta
	if drain_timer >= 1.5:
		drain_timer = 0.0
		take_damage(1)
	
	#Kill player if out of bounds
	if position.y > floorbound:
		take_damage(health)
	
	update_audio_timers(delta)
	
	
	potentialGrappleLight = find_closest_light(get_global_mouse_position())
	if (potentialGrappleLight != null):
		potentialGrappleLight.LightUp()
	
	if (!interacting):
		if (calculate_movement(delta)):
			move_and_slide()
	
	## To make something interactable, make sure it's a collision object (can be body or area),
	## make sure it's on collision layer 2, and make sure it has a function called 'interact()'
	if Input.is_action_just_pressed("interact"):
		if is_on_floor() and not interacting:
			interacte()
		
	update_sprite(delta)
		
func calculate_movement(delta: float):
	lastInput = input
	input = Input.get_axis("move_left", "move_right")
	inputDirty = (input != lastInput)
	
	lastStage = currentStage
	
	##### Compute the current stage #####
	
	if (lastStage == Stage.GROUND):
		if (Input.is_action_just_pressed("jump")):
			currentStage = Stage.JUMP
		elif (!is_on_floor()):
			currentStage = Stage.FALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && potentialGrappleLight != null && canGrapple):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.JUMP):
		if (Input.is_action_just_released("jump")):
			velocity.y = 0
			currentStage = Stage.FALL
		elif (velocity.y >= 0):
			currentStage = Stage.FALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && potentialGrappleLight != null && canGrapple):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.FALL):
		if (is_on_floor()):
			currentStage = Stage.GROUND
			try_play_audio("land")
		elif (is_on_wall()):
			currentStage = Stage.WALL
			try_play_audio("land")
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && potentialGrappleLight != null && canGrapple):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.WALL):
		if (is_on_floor()):
			currentStage = Stage.GROUND
		elif (!is_on_wall()):
			currentStage = Stage.FALL
		elif (Input.is_action_just_pressed("jump")):
			for i in range(get_slide_collision_count()):
				wallNormal = sign(get_slide_collision(i).get_normal().x)
			currentStage = Stage.WALLJUMP
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && potentialGrappleLight != null && canGrapple):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.WALLJUMP):
		if (velocity.y >= 0):
			currentStage = Stage.FALL
		elif (is_on_wall()):
			currentStage = Stage.WALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && potentialGrappleLight != null && canGrapple):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.GRAPPLE):
		if (position == grappleTarget):
			disable_grapple_visual()
			currentStage = Stage.FALL
		elif (is_on_wall() || is_on_ceiling() || is_on_floor()):
			disable_grapple_visual()
			currentStage = Stage.FALL
			
			
	##### Enable/Disable grappling #####
	
	if (currentStage == Stage.GROUND || currentStage == Stage.WALL):
		canGrapple = true;
	elif (currentStage == Stage.GRAPPLE):
		canGrapple = false;
		
	##### Compute movement based on current stage #####
	
	if (currentStage == Stage.GROUND):
		return handle_stage_ground(delta, input)
	elif (currentStage == Stage.JUMP):
		return handle_stage_jump(delta, input)
	elif (currentStage == Stage.FALL):
		return handle_stage_fall(delta, input)
	elif (currentStage == Stage.WALL):
		return handle_stage_wall(delta, input)
	elif (currentStage == Stage.WALLJUMP):
		return handle_stage_walljump(delta, input)
	elif (currentStage == Stage.GRAPPLE):
		return handle_stage_grapple(delta, input)
	else:
		return false;

func handle_stage_ground(delta: float, inputAxis: float):
	velocity.x = inputAxis * speed
	if (inputAxis != 0):
		try_play_audio("walk")
		#Collision with block
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider is RigidBody2D:
				collider.apply_central_impulse(-collision.get_normal() * pushforce)
		
	return true
	
func handle_stage_jump(delta: float, inputAxis: float):
	if (lastStage != Stage.JUMP):
		velocity.y = -jump_speed
	velocity.x = inputAxis * speed
	velocity.y += gravity * delta
	return true
	
func handle_stage_fall(delta: float, inputAxis: float):
	if (inputDirty):
		velocity.x = inputAxis * speed
	velocity.y += gravity * delta
	return true
	
func handle_stage_wall(delta: float, inputAxis: float):
	velocity.x = inputAxis * speed
	velocity.y = wall_slide_speed
	return true
	
func handle_stage_walljump(delta: float, inputAxis: float):
	if (lastStage != Stage.WALLJUMP):
		velocity.y = -jump_speed
		velocity.x = wall_jump_speed * wallNormal
	velocity.y += gravity * delta
	if (inputAxis != 0 && sign(inputAxis) != sign(wallNormal)):
		velocity.x += inputAxis * speed * delta * 4
	return true
		
func handle_stage_grapple(delta: float, inputAxis: float):
	if (lastStage != Stage.GRAPPLE):
		grappleTarget = potentialGrappleLight.position;
		grappleStart = position
		try_play_audio("grapple")
	var currentDirection = (grappleTarget - position).normalized()
	var percent = ((position - grappleStart).length() / (grappleTarget - grappleStart).length())
	
	var finalInitialDelta = grapple_final_velocity - grapple_initial_velocity
	var currentVelocity = currentDirection * ((finalInitialDelta * percent) + grapple_initial_velocity);
	var nextPos = position + (currentVelocity * delta)
	
	velocity = currentVelocity
	
	if (sign(grappleTarget.x - grappleStart.x) != sign(grappleTarget.x - nextPos.x) or sign(grappleTarget.y - grappleStart.y) != sign(grappleTarget.y - nextPos.y)):
		position = grappleTarget
		return false
	
	apply_grapple_visual(nextPos, grappleTarget)
	
	return true

func update_sprite(delta: float) -> void:
	var fps30delta = delta * 30
	
	if (abs(velocity.x) > 0):
		facing_right = velocity.x > 0
	$Sprite.flip_h = !facing_right
	
	var currentAnimBase
	
	var _jump = 0
	var _fall = 6
	var _grapple = 7
	var _idle = 19
	var _walljump = 54
	var _run = 55
	var _wall = 86
	
	if (currentStage == Stage.FALL):
		currentAnimBase = _fall
		currentAnimOffset = 0
	elif (currentStage == Stage.WALL):
		currentAnimBase = _wall
		currentAnimOffset = 0
	elif (currentStage == Stage.WALLJUMP):
		currentAnimBase = _walljump
		currentAnimOffset = 0
	elif (currentStage == Stage.JUMP):
		currentAnimBase = _jump
		currentAnimOffset = min(currentAnimOffset + fps30delta, _fall)
	elif (currentStage == Stage.GRAPPLE):
		currentAnimBase = _grapple
		var frameWidth: int = _idle - _grapple
		currentAnimOffset = fmod(currentAnimOffset + fps30delta, frameWidth)
	elif (currentStage == Stage.GROUND):
		if (velocity.x == 0):
			currentAnimBase = _idle
		else:
			currentAnimBase = _run
		if (abs(velocity.x) > 0):
			var frameWidth: int = _wall - _run
			currentAnimOffset = fmod(currentAnimOffset + fps30delta, frameWidth)
		else:
			var frameWidth: int = _run - _walljump
			currentAnimOffset = fmod(currentAnimOffset + fps30delta, frameWidth)
			
	if (interacting):
		jump_to_frame_index(4)
	else:
		jump_to_frame_index(currentAnimBase + currentAnimOffset)
	
	# I think interact box centered on player is better but you can change it back if you want
	#$InteractBox.position.x = 6 if facing_right else -6

func jump_to_frame_index(index: float):
	var intIndex: int = floor(index)
	var pos = Vector2i(intIndex % 11, intIndex / 11)
	$Sprite.frame_coords = pos
	
func interacte():
	for target in $InteractBox.get_overlapping_bodies():
		if target.has_method("interact"):
			interacting = true
			target.interact()
	await get_tree().create_timer(0.25).timeout
	interacting = false
	
func find_closest_light(sourcePos: Vector2):
	var lights = get_tree().get_nodes_in_group("light")
	
	var closestLight = null
	var closestLightDistance = 1000000;

	for light: Node2D in lights:
		var currentDistance = (light.position - sourcePos).length()
		if (currentDistance < closestLightDistance && (position - light.position).length() <= grapple_max_reach):
			closestLight = light
			closestLightDistance = currentDistance
	
	return closestLight

func apply_grapple_visual(pos1: Vector2, pos2: Vector2):
	$Grapple.clear_points()
	$Grapple.add_point(pos1 - position)
	$Grapple.add_point(pos2 - position)

func disable_grapple_visual():
	$Grapple.clear_points()
	
func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		#get_tree().call_deferred("reload_current_scene")
		health = 100
		position = Vector2(checkpos1, checkpos2)

func update_audio_timers(delta: float):
	audioTimerWalk = max(audioTimerWalk - delta, 0)
	
func try_play_audio(name: String):
	if (name == "walk" && audioTimerWalk == 0):
		$WalkPlayer.pitch_scale = randf_range(0.85, 1)
		$WalkPlayer.play()
		audioTimerWalk = 0.4
	elif (name == "land"):
		$WalkPlayer.pitch_scale = 0.75
		$WalkPlayer.play()
	elif (name == "grapple"):
		$GrapplePlayer.pitch_scale = 1
		$GrapplePlayer.play()
