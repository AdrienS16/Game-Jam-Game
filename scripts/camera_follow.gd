extends Camera2D

@export var followTarget : Node2D 
@export var followSpeed : float = 5

func _ready() -> void:
	if followTarget:
		position = followTarget.position

func _process(delta: float) -> void:
	if followTarget:
		position = lerp(position, followTarget.position, delta * followSpeed)
