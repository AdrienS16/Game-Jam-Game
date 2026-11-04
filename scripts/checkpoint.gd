extends Sprite2D
@export var framecoord1 := 0
@export var framecoord2 := 0
@export var framenumber := framecoord1 + framecoord2
# Retrieve player data from scene
@onready var player_node: CharacterBody2D = get_parent().get_node("Player")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	# Hitbox collides with spike
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Checks if hitbox is player's
	if body == player_node:
		# Deals 100 damage to player
		player_node.take_damage(100)
