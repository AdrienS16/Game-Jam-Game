extends Sprite2D

# Retrieve player data from scene
@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

# Hitbox collides with spike
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Checks if hitbox is player's
	if body == player_node:
		# Deals 100 damage to player
		player_node.take_damage(player_node.health)
