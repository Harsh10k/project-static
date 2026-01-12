extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	SEARCH,
	RETURN
}

var spawn_position: Vector2
var current_state: State = State.IDLE
var direction: Vector2

@export var idle_speed: int = 80
@export var idle_pause_duration: float = 1.3
@export var idle_move_duration: float = 2.0
@export var turn_speed: float = 80.0


@export var idle_inner_radius: float = 48.0
@export var idle_outer_radius: float = 192.0

var temp_spawn_position: Vector2
var using_temp_spawn: bool = false
var temp_spawn_timer: float = 0.0

@export var temp_spawn_duration: float = 6.0

var idle_timer: float = 0.0
var idle_direction: Vector2 = Vector2.ZERO
var idle_pausing: bool = true

@export var speed: int = 225
@export var slow_down_rate: float = 100.0

@export var search_speed: int = 120
@export var search_duration: float = 2.5

var search_timer: float = 0.0
var search_direction: Vector2 = Vector2.ZERO

var player: CharacterBody2D


func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if using_temp_spawn:
		temp_spawn_timer -= delta
		if temp_spawn_timer <= 0.0:
			using_temp_spawn = false
			current_state = State.RETURN


	match current_state:
		State.IDLE:
			idle_state(delta)
		State.CHASE:
			chase_state(delta)
		State.SEARCH:
			search_state(delta)
		State.RETURN:
			return_state(delta)
	queue_redraw()


func idle_state(delta: float) -> void:
	# Always allow instant interrupt
	if player:
		current_state = State.CHASE
		return

	idle_timer -= delta

	if idle_pausing:
		# Smoothly slow down while pausing
		velocity = velocity.move_toward(Vector2.ZERO, slow_down_rate * delta)
		move_and_slide()

		if idle_timer <= 0.0:
			# Start moving
			idle_pausing = false
			idle_timer = idle_move_duration
			idle_direction = choose_idle_direction()
	else:
		# Move phase
		var target_velocity = idle_direction * idle_speed
		velocity = velocity.move_toward(target_velocity, turn_speed * delta)

		move_and_slide()

		if idle_timer <= 0.0:
			# Go back to pause
			idle_pausing = true
			idle_timer = idle_pause_duration

func choose_idle_direction() -> Vector2:
	var center = get_idle_center()
	var to_center = center - global_position

	var distance = to_center.length()

	# Too far → bias inward
	if distance > idle_outer_radius:
		return to_center.normalized()

	# Too close → bias outward
	if distance < idle_inner_radius:
		return (-to_center).normalized()

	# Otherwise random wander
	return Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()
	
func get_idle_center() -> Vector2:
	if using_temp_spawn:
		return temp_spawn_position
	return spawn_position

func chase_state(delta: float) -> void:
	if not player:
		current_state = State.SEARCH
		search_timer = search_duration
		search_direction = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		return

	var dir = (player.position - position).normalized()
	var target_velocity = dir * speed
	velocity = velocity.move_toward(target_velocity, turn_speed * delta)
	move_and_slide()

	
func search_state(delta: float) -> void:
	search_timer -= delta

	if search_timer <= 0:
		current_state = State.IDLE
		
		temp_spawn_position = global_position
		using_temp_spawn = true
		temp_spawn_timer = temp_spawn_duration
		
		idle_pausing = true
		idle_timer = idle_pause_duration
		return

	var target_velocity = search_direction * search_speed
	velocity = velocity.move_toward(target_velocity, turn_speed * delta)

	move_and_slide()

func _on_detection_area_body_entered(player_body: CharacterBody2D) -> void:
	player = player_body
	current_state = State.CHASE

func _on_detection_area_body_exited(_player_body: CharacterBody2D) -> void:
	player = null
	current_state = State.SEARCH
	search_timer = search_duration
	search_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

@export var return_speed: int = 140
@export var return_distance_threshold: float = 6.0

func return_state(delta: float) -> void:
	var to_spawn = spawn_position - global_position

	if to_spawn.length() <= return_distance_threshold:
		# Reached home → switch to idle
		current_state = State.IDLE
		idle_pausing = true
		idle_timer = idle_pause_duration
		return

	var dir = to_spawn.normalized()
	var target_velocity = dir * return_speed
	velocity = velocity.move_toward(target_velocity, turn_speed * delta)

	move_and_slide()

# debug

func _draw() -> void:
	var center = get_idle_center()
	var local_center = to_local(center)

	# Inner radius (red)
	draw_circle(local_center, idle_inner_radius, Color(1, 0, 0, 0.6))

	# Outer radius (blue)
	draw_circle(local_center, idle_outer_radius, Color(0, 0, 1, 0.6))
