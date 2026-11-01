extends TextureProgressBar

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)
	max_value = player.max_health
	value = player.health
	_update_color()

func _on_health_changed(new_health: int) -> void:
	value = new_health
	_update_color()

func _update_color() -> void:
	if value > 66:
		tint_progress = Color.GREEN
	elif value > 33:
		tint_progress = Color.YELLOW
	else:
		tint_progress = Color.RED
