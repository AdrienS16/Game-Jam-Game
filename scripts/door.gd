extends StaticBody2D

var open = false

func interact():
	open = !open
	
	collision_layer = 2 if open else 3
	
	if open:
		$Door.frame = 1
		if get_tree().get_first_node_in_group("player").position.x < position.x:
			$Door.position.x = 2
		else:
			$Door.position.x = -2
	else:
		$Door.frame = 0
		$Door.position.x = 0
