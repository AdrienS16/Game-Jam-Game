class_name Player extends CharacterBody2D

@export var gravity := 350.0
@export var speed := 75.0
@export var jump_speed := 160.0
@export var wall_jump_speed := 80.0
@export var wall_slide_speed := 50.0;
@export var grapple_accel := 10.0

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

var grappleTarget
var grappleStart

func _process(delta: float) -> void:
	if (!interacting):
		CalculateMovement(delta)
		move_and_slide()
	
	## To make something interactable, make sure it's a collision object (can be body or area),
	## make sure it's on collision layer 2, and make sure it has a function called 'interact()'
	if Input.is_action_just_pressed("interact"):
		if is_on_floor() and not interacting:
			interact()
		
	update_sprite()
		
func CalculateMovement(delta: float):
	var input = Input.get_axis("move_left", "move_right")
	lastStage = currentStage
	
	##### Compute the current stage #####
	
	if (lastStage == Stage.GROUND):
		if (Input.is_action_just_pressed("jump")):
			currentStage = Stage.JUMP
		elif (!is_on_floor()):
			currentStage = Stage.FALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.JUMP):
		if (Input.is_action_just_released("jump")):
			velocity.y = 0
			currentStage = Stage.FALL
		elif (velocity.y >= 0):
			currentStage = Stage.FALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.FALL):
		if (is_on_floor()):
			currentStage = Stage.GROUND
		elif (is_on_wall()):
			currentStage = Stage.WALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
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
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.WALLJUMP):
		if (velocity.y >= 0):
			currentStage = Stage.FALL
		elif (is_on_wall()):
			currentStage = Stage.WALL
		elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			currentStage = Stage.GRAPPLE
			
	elif (lastStage == Stage.GRAPPLE):
		if (position == grappleTarget):
			currentStage = Stage.FALL
		elif (is_on_wall() || is_on_ceiling() || is_on_floor()):
			currentStage = Stage.FALL
		
	##### Compute movement based on current stage #####
	
	if (currentStage == Stage.GROUND):
		handle_stage_ground(delta, input)
	elif (currentStage == Stage.JUMP):
		handle_stage_jump(delta, input)
	elif (currentStage == Stage.FALL):
		handle_stage_fall(delta, input)
	elif (currentStage == Stage.WALL):
		handle_stage_wall(delta, input)
	elif (currentStage == Stage.WALLJUMP):
		handle_stage_walljump(delta, input)
	elif (currentStage == Stage.GRAPPLE):
		handle_stage_grapple(delta, input)

func handle_stage_ground(delta: float, inputAxis: float):
	velocity.x = inputAxis * speed
	
func handle_stage_jump(delta: float, inputAxis: float):
	if (lastStage != Stage.JUMP):
		velocity.y = -jump_speed
	velocity.x = inputAxis * speed
	velocity.y += gravity * delta
	
func handle_stage_fall(delta: float, inputAxis: float):
	velocity.x = inputAxis * speed
	velocity.y += gravity * delta
	
func handle_stage_wall(delta: float, inputAxis: float):
	velocity.x = inputAxis * speed
	velocity.y = wall_slide_speed
	
func handle_stage_walljump(delta: float, inputAxis: float):
	if (lastStage != Stage.WALLJUMP):
		velocity.y = -jump_speed
		velocity.x = wall_jump_speed * wallNormal
	velocity.y += gravity * delta
	if (inputAxis != 0 && sign(inputAxis) != sign(wallNormal)):
		velocity.x += inputAxis * speed * delta * 4
		
func handle_stage_grapple(delta: float, inputAxis: float):
	if (lastStage != Stage.GRAPPLE):
		grappleTarget = get_global_mouse_position()
		grappleStart = position
	var currentDelta = grappleTarget - position
	var grappleAmountSecs = velocity + (currentDelta.normalized() * grapple_accel)
	var nextPos = position + (grappleAmountSecs * delta)
	if (sign(grappleTarget.x - grappleStart.x) != sign(grappleTarget.x - nextPos.x) or sign(grappleTarget.y - grappleStart.y) != sign(grappleTarget.y - nextPos.y)):
		velocity = Vector2(0, 0)
		position = grappleTarget
		return
	velocity = grappleAmountSecs

func update_sprite():
	var input = Input.get_axis("move_left", "move_right")
	
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
