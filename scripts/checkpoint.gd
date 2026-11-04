extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

@export var framecoord1 := 0
@export var framecoord2 := 0
@export var framenumber := framecoord1 + framecoord2

var active = false
var activating = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if activating == true:
		animated_sprite.play("Activate")
		activating = false
	else:
		if active == false:
			animated_sprite.play("Dormant")
		else:
			await $AnimatedSprite2D.animation_finished
			animated_sprite.play("Active")

# Hitbox collides with checkpoint
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Checks if hitbox is player's
	if body == player_node:
		# Activate checkpoint
		if active == false and activating == false:
			activating = true
			active = true
			player_node.checkpos1 = position.x
			player_node.checkpos2 = position.y
