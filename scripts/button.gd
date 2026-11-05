extends StaticBody2D

signal used
signal unused

var pushed = false
@export var toggle = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if pushed == false:
		pushed = true
		used.emit()
		$Button.frame = 1

#func _on_area_2d_body_exited(body: Node2D) -> void:
#	if pushed == true:
#		pushed = false
#		unused.emit()
#		$Button.frame = 0
