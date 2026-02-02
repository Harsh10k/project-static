extends CharacterBody2D

signal health_changed

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2
@export var speed: int = 500

@export var max_health = 8
@onready var current_health: int = max_health

@export var knockback_power: int = 500

@onready var muzzle: Marker2D = $Marker2D
@onready var fire_timer: Timer = Timer.new()

var input_direction: Vector2
var last_anim_direction: String = "Down"
var is_hurt: bool = false
var is_attacking: bool = false

func _ready() -> void:
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	add_child(fire_timer)
	
func increase_health():
	if current_health >= max_health: return 
	current_health += 1

func _physics_process(_delta: float) -> void:
	# Movement
	input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()

	# Continuous shooting while left click is held
	if Input.is_action_pressed("left_click"):
		shoot()
		
	if !is_hurt:
		for area in hurt_box.get_overlapping_areas():
			if area.name == "hit_box":
				hurt_by_enemy(area)

func shoot() -> void:
	# Enforce fire rate
	if not fire_timer.is_stopped():
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = (
		get_global_mouse_position() - muzzle.global_position
	).normalized()

	get_tree().current_scene.add_child(bullet)
	fire_timer.start()
	
func hurt_by_enemy(area):
	current_health -= 1
	if current_health < 0:
		current_health = max_health	
	
	is_hurt = true
	health_changed.emit()
	
	knockback(area.get_parent().velocity)
	is_hurt = false
		
func knockback(enemy_velocity: Vector2):
	var knockback_direction = (enemy_velocity - velocity).normalized() * knockback_power
	velocity = knockback_direction
	move_and_slide()
