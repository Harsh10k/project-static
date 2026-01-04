extends CharacterBody2D

@export var speed: int = 500
var input_direction: Vector2

func _physics_process(_delta: float) -> void:
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	velocity = input_direction * speed
	move_and_slide()
