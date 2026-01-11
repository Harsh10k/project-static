extends CharacterBody2D

var direction: Vector2
@export var speed: int = 225
var player: CharacterBody2D

func _on_detection_area_body_entered(player_body: CharacterBody2D) -> void:
	player = player_body

func _physics_process(delta: float) -> void:
	if player:
		var dir = (player.position - position).normalized()
		velocity = dir * speed
		move_and_slide()



func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
