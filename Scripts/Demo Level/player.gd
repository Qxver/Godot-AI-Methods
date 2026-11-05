extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 0.5
@export var attack_speed_scale: float = 1.75

var current_hp: int
var last_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false
var is_attacking: bool = false

var _hit_flash_timer: float = 0.0
const HIT_FLASH_DURATION: float = 0.15

signal died
signal hp_changed(new_hp: int, max_hp: int)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Player")
	health_bar.max_value = max_hp
	health_bar.value     = max_hp
	for anim in ["AttackDown", "AttackRight", "AttackUp"]:
		animated_sprite.sprite_frames.set_animation_loop(anim, false)
	animated_sprite.animation_finished.connect(_on_attack_animation_finished)

func _physics_process(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			animated_sprite.modulate = Color.WHITE

	if is_dead:
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
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

	if Input.is_action_just_pressed("attack"):
		_perform_attack()

func _perform_attack() -> void:
	is_attacking = true
	_play_attack_animation()

	var facing := last_direction.normalized()
	var hit_origin := global_position + facing * (attack_range * 0.6)

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not enemy.has_method("take_damage"):
			continue
		var to_enemy: Vector2 = (enemy as Node2D).global_position - global_position
		var dist: float = to_enemy.length()
		if dist > attack_range:
			continue
		# Dot product: 1.0 = wprost przed graczem, 0.0 = bok, -1.0 = plecy
		# Próg 0.3 ≈ łuk ~120° przed graczem (cos(72°) ≈ 0.3)
		var dot := facing.dot(to_enemy.normalized())
		if dot >= 0.3:
			enemy.take_damage(attack_damage)

func _on_attack_animation_finished() -> void:
	var current_anim: String = animated_sprite.animation
	if current_anim in ["AttackDown", "AttackRight", "AttackUp"]:
		is_attacking = false
		animated_sprite.speed_scale = 1.0
		_play_idle_animation()

func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		_play_idle_animation()
	else:
		last_direction = direction
		_play_walk_animation(direction)

func _play_attack_animation() -> void:
	animated_sprite.speed_scale = attack_speed_scale
	if abs(last_direction.x) >= abs(last_direction.y):
		animated_sprite.flip_h = last_direction.x < 0
		animated_sprite.play("AttackRight")
	elif last_direction.y < 0:
		animated_sprite.flip_h = false
		animated_sprite.play("AttackUp")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("AttackDown")

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
	is_attacking = false
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(0.4, 0.4, 0.4)
	died.emit()
	# Todo animacja smierci
