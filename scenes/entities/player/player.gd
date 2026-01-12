extends CharacterBody2D


@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2

@onready var muzzle = $Marker2D
@onready var fire_timer = Timer.new()

@export var speed: int = 500
var input_direction: Vector2


func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	add_child(fire_timer)

func _physics_process(_delta: float) -> void:
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	look_at(get_global_mouse_position())
	
	velocity = input_direction * speed
	move_and_slide()

func _input(event):
	if event.is_action_pressed("left_click"):
		shoot()

func shoot():
	if not fire_timer.is_stopped():
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = (get_global_mouse_position() - muzzle.global_position).normalized()
	get_tree().current_scene.add_child(bullet)

	fire_timer.start()
