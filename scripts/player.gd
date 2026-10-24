class_name Player extends CharacterBody2D

@export var speed := 75.0
@export var jump_speed := 160.0
@export var gravity := 350.0
@export var grapple_accel := 1.0

var facing_right = false
var interacting = false
var grappling = false

var grappleTarget = Vector2(0, 0)
var grappleDelta = Vector2(0, 0)

func _process(delta: float) -> void:
	# Handle movement
	var input = Input.get_axis("move_left", "move_right")
	if interacting:
		input = 0
	
	if (not grappling):
		velocity.x = input * speed
		
		# Handle jumping
		velocity.y += gravity * delta
		if Input.is_action_just_pressed("jump"):
			if is_on_floor() and not interacting:
				velocity.y = -jump_speed
		if Input.is_action_just_released("jump"):
			if velocity.y < 0:
				velocity.y = 0
		
		# To make something interactable, make sure it's a collision object (can be body or area),
		# make sure it's on collision layer 2, and make sure it has a function called 'interact()'
		if Input.is_action_just_pressed("interact"):
			if is_on_floor() and not interacting:
				interact()
			
	#Handle grapple
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if (not grappling):
			grappling = true
			grappleTarget = get_global_mouse_position()
	
	#Calculate grapple if grappling
	if (grappling):
		calculate_grapple()
		
	move_and_slide()	
	update_sprite()


func calculate_grapple():
	var newDelta = grappleTarget - position
	if (grappleDelta != Vector2(0, 0) and (sign(newDelta.x) != sign(grappleDelta.x) or sign(newDelta.y) != sign(grappleDelta.y))):
		grappling = false
		velocity = Vector2(0, 0)
		grappleDelta = Vector2(0, 0)
		return
	
	grappleDelta = newDelta
	var grappleAmount = grappleDelta.normalized() * grapple_accel
	velocity += grappleAmount;

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
	interacting = true
	for target in $InteractBox.get_overlapping_bodies():
		if target.has_method("interact"):
			target.interact()
	for target in $InteractBox.get_overlapping_areas():
		if target.has_method("interact"):
			target.interact()
	await get_tree().create_timer(0.25).timeout
	interacting = false
