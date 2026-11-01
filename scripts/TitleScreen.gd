extends Button

func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_leave_button_pressed() -> void:
	get_tree().quit()
