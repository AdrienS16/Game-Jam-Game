extends CharacterBody2D

@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

var speed: float = 35.0
var gravity = 15

@export_range(-1, 1) var dir: int = 1

func _ready() -> void:
	if dir == 0:
		dir = 1
	$Sprite2D.flip_h = false if dir == 1 else true

func _physics_process(delta: float) -> void:
	if dir == 1 and (!$rightray.is_colliding() or $rightwallray.is_colliding()):
		$Sprite2D.flip_h = true
		dir = 0
		_wait_dir_change(-1)
	if dir == -1 and (!$leftray.is_colliding() or $leftwallray.is_colliding()):
		$Sprite2D.flip_h = false
		dir = 0
		_wait_dir_change(1)
	
	velocity.x = lerp(velocity.x, dir * speed, 10.0*delta)
	velocity.y += gravity
	move_and_slide()

func _wait_dir_change(desired_dir: int):
	await get_tree().create_timer(0.5).timeout
	dir = desired_dir

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player_node:
		get_tree().call_deferred("reload_current_scene")
