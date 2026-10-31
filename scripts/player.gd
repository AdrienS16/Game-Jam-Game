class_name Player extends CharacterBody2D

@export var gravity := 350.0
@export var speed := 75.0
@export var jump_speed := 160.0
@export var wall_jump_speed := 80.0
@export var wall_slide_speed := 50.0;
@export var grapple_final_velocity := 175.0
@export var grapple_initial_velocity := 50.0
@export var grapple_max_reach := 75

var facing_right = false
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

func _process(delta: float) -> void:
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
			interact()
		
	update_sprite()
		
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
		elif (is_on_wall()):
			currentStage = Stage.WALL
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

func update_sprite():
	# Update sprite
	if input > 0:
		facing_right = true
	if input < 0:
		facing_right = false
	
	$InteractBox.position.x = 6 if facing_right else -6
	
	$Sprite.frame_coords.y = 2 if facing_right else 0
	if not is_on_floor():
		$Sprite.frame_coords.y += 1
		$Sprite.frame_coords.x = 1 if velocity.y > 0 else 0
	elif abs(velocity.x) > 0:
		var time_elapsed = Time.get_ticks_msec() / 1000.0
		$Sprite.frame_coords.x = int(time_elapsed * 10) % 6 + 1
	elif interacting:
		$Sprite.frame_coords.x = 7
	else:
		$Sprite.frame_coords.x = 0

func interact():
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
