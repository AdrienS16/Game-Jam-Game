extends Label

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)
	text = str(player.health) + "%"

func _on_health_changed(new_health: int) -> void:
	text = str(new_health) + "%"
