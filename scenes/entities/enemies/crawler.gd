extends CharacterBody2D

enum State {
	IDLE,
	CHASE
}

var current_state: State = State.IDLE
var spawn_position: Vector2

var direction: Vector2
@export var speed: int = 225
@export var slow_down_rate: float = 100.0

var player: CharacterBody2D

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.CHASE:
			chase_state(delta)

func idle_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, slow_down_rate * delta)
	move_and_slide()

func chase_state(delasdta: float) -> void:
	if not player:
		current_state = State.IDLE
		return

	var dir = (player.position - position).normalized()
	velocity = dir * speed
	move_and_slide()

func _on_detection_area_body_entered(player_body: CharacterBody2D) -> void:
	player = player_body
	current_state = State.CHASE

func _on_detection_area_body_exited(_player_body: CharacterBody2D) -> void:
	player = null
	current_state = State.IDLE
