extends CharacterBody2D

@export var config: EnemyConfig   # 👈 THIS makes it modular

enum State {
	IDLE,
	CHASE,
	SEARCH,
	RETURN
}

var current_state: State = State.IDLE

var spawn_position: Vector2
var temp_spawn_position: Vector2
var using_temp_spawn := false
var temp_spawn_timer := 0.0

var player: CharacterBody2D

var idle_timer := 0.0
var idle_pausing := true
var idle_direction := Vector2.ZERO
var current_idle_direction := Vector2.ZERO

var search_timer := 0.0
var search_direction := Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position
	enter_idle()

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

func enter_idle() -> void:
	idle_pausing = true
	idle_timer = config.idle_pause_duration
	idle_direction = choose_idle_direction()
	current_idle_direction = idle_direction

func idle_state(delta: float) -> void:
	if player:
		current_state = State.CHASE
		return

	idle_timer -= delta

	if idle_pausing:
		var drift_velocity = current_idle_direction * 20.0
		velocity = velocity.move_toward(
			drift_velocity,
			config.slow_down_rate * delta
		)
		move_and_slide()

		if idle_timer <= 0.0:
			idle_pausing = false
			idle_timer = config.idle_move_duration
			idle_direction = choose_idle_direction()
	else:
		current_idle_direction = current_idle_direction.lerp(
			idle_direction,
			config.direction_smoothness * delta
		).normalized()

		var target_velocity = current_idle_direction * config.idle_speed
		velocity = velocity.move_toward(
			target_velocity,
			config.turn_speed * delta
		)
		move_and_slide()

		if idle_timer <= 0.0:
			idle_pausing = true
			idle_timer = config.idle_pause_duration

func choose_idle_direction() -> Vector2:
	var center = get_idle_center()
	var to_center = center - global_position
	var distance = to_center.length()

	if distance > config.idle_outer_radius:
		return to_center.normalized()

	if distance < config.idle_inner_radius:
		return (-to_center).normalized()

	return Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

func get_idle_center() -> Vector2:
	return temp_spawn_position if using_temp_spawn else spawn_position

func chase_state(delta: float) -> void:
	if not player:
		current_state = State.SEARCH
		search_timer = config.search_duration
		search_direction = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		return

	var dir = (player.global_position - global_position).normalized()
	var target_velocity = dir * config.speed
	velocity = velocity.move_toward(
		target_velocity,
		config.turn_speed * delta
	)
	move_and_slide()

func search_state(delta: float) -> void:
	search_timer -= delta

	if search_timer <= 0.0:
		temp_spawn_position = global_position
		using_temp_spawn = true
		temp_spawn_timer = config.temp_spawn_duration

		current_state = State.IDLE
		enter_idle()
		return

	var target_velocity = search_direction * config.search_speed
	velocity = velocity.move_toward(
		target_velocity,
		config.turn_speed * delta
	)
	move_and_slide()

func return_state(delta: float) -> void:
	var to_spawn = spawn_position - global_position

	if to_spawn.length() <= config.return_distance_threshold:
		current_state = State.IDLE
		enter_idle()
		return

	var dir = to_spawn.normalized()
	var target_velocity = dir * config.return_speed
	velocity = velocity.move_toward(
		target_velocity,
		config.turn_speed * delta
	)
	move_and_slide()

func _on_detection_area_body_entered(body: CharacterBody2D) -> void:
	player = body
	current_state = State.CHASE

func _on_detection_area_body_exited(_body: CharacterBody2D) -> void:
	player = null
	current_state = State.SEARCH
	search_timer = config.search_duration
	search_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

func _draw() -> void:
	var center = get_idle_center()
	var local_center = to_local(center)

	draw_circle(local_center, config.idle_inner_radius, Color(1, 0, 0, 0.6))
	draw_circle(local_center, config.idle_outer_radius, Color(0, 0, 1, 0.6))
