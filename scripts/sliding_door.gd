extends Node2D

var open = false

func open_door():
	if open:
		return
	open = true
	var tween = create_tween()
	tween.tween_property($Node2D, "position", Vector2(0, -16), 0.25)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

func close_door():
	if not open:
		return
	open = false
	var tween = create_tween()
	tween.tween_property($Node2D, "position", Vector2(0, 0), 0.25)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
