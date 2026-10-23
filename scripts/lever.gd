extends StaticBody2D

signal used
signal unused

var pulled = false
@export var toggle = false

func interact():
	if not pulled:
		pulled = true
		used.emit()
		$Lever.frame = 1
	else:
		if toggle:
			pulled = false
			unused.emit()
			$Lever.frame = 0
