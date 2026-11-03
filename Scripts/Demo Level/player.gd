extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

@export var max_hp: int = 100

var current_hp: int
var last_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

var _hit_flash_timer: float = 0.0
const HIT_FLASH_DURATION: float = 0.15

signal died
signal hp_changed(new_hp: int, max_hp: int)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Player")
	health_bar.max_value = max_hp
	health_bar.value     = max_hp

func _physics_process(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			animated_sprite.modulate = Color.WHITE

	if is_dead:
		return

	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * 100.0
	move_and_slide()

	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		_play_idle_animation()
	else:
		last_direction = direction
		_play_walk_animation(direction)

func _play_walk_animation(direction: Vector2) -> void:
	if abs(direction.x) >= abs(direction.y):
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play("WalkRight")
	elif direction.y < 0:
		animated_sprite.flip_h = false
		animated_sprite.play("WalkUp")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("WalkDown")

func _play_idle_animation() -> void:
	if abs(last_direction.x) >= abs(last_direction.y):
		animated_sprite.flip_h = last_direction.x < 0
		animated_sprite.play("IdleRight")
	elif last_direction.y < 0:
		animated_sprite.flip_h = false
		animated_sprite.play("IdleUp")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("Idle")

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)
	health_bar.value = current_hp
	hp_changed.emit(current_hp, max_hp)

	animated_sprite.modulate = Color(1.0, 0.25, 0.25)
	_hit_flash_timer = HIT_FLASH_DURATION

	if current_hp <= 0:
		_die()



func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(0.4, 0.4, 0.4)
	died.emit()
	# Todo animacja smierci
