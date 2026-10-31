extends Node

var litUp = false # because light is called after player

func _ready() -> void:
	add_to_group("light")

func _process(delta: float) -> void:
	if litUp:
		$Sprite.frame_coords.x = 1
	else:
		$Sprite.frame_coords.x = 0
	litUp = false

func LightUp():
	litUp = true
