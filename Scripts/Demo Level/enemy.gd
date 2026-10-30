extends CharacterBody2D

@export var wander_speed   : float = 20.0
@export var chase_speed    : float = 40.0
@export var detect_range   : float = 80.0  
@export var lose_range     : float = 140.0   
@export var attack_range   : float = 20.0   
@export var wander_min_time: float = 1.0
@export var wander_max_time: float = 3.0
@export var pause_min_time : float = 0.5  
@export var pause_max_time : float = 1.5   

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum EnemyState { IDLE, FOLLOW, ATTACK, DEATH }

var current_state : EnemyState = EnemyState.IDLE
var player        : CharacterBody2D

var wander_direction : Vector2
var wander_timer     : float
var pause_timer      : float = 0.0
var is_pausing       : bool  = false

var is_dead : bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	sprite.play("IdleDown")
	_enter_idle()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match current_state:
		EnemyState.IDLE:
			_update_idle(delta)
		EnemyState.FOLLOW:
			_update_follow(delta)
		EnemyState.ATTACK:
			_update_attack(delta)

	move_and_slide()


func _enter_idle() -> void:
	_start_pause()


func _start_pause() -> void:
	is_pausing       = true
	pause_timer      = randf_range(pause_min_time, pause_max_time)
	wander_direction = Vector2.ZERO


func _start_wander() -> void:
	is_pausing       = false
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer     = randf_range(wander_min_time, wander_max_time)


func _update_idle(delta: float) -> void:
	if is_pausing:
		velocity = Vector2.ZERO
		_play_directional("Idle")

		pause_timer -= delta
		if pause_timer <= 0.0:
			_start_wander()
	else:
		velocity = wander_direction * wander_speed

		wander_timer -= delta
		if wander_timer <= 0.0:
			_start_pause()

		_play_walk_or_idle_anim(velocity, "Idle")

	if player and _dist_to_player() < detect_range:
		_transition(EnemyState.FOLLOW)


func _enter_follow() -> void:
	pass


func _update_follow(delta: float) -> void:
	if not player:
		_transition(EnemyState.IDLE)
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * chase_speed

	_play_walk_or_idle_anim(velocity, "Idle")

	var dist := _dist_to_player()

	if dist > lose_range:
		_transition(EnemyState.IDLE)
	elif dist < attack_range:
		_transition(EnemyState.ATTACK)


func _enter_attack() -> void:
	velocity = Vector2.ZERO
	_play_attack_anim()


func _update_attack(_delta: float) -> void:
	if not player:
		_transition(EnemyState.IDLE)
		return

	velocity = Vector2.ZERO

	if _dist_to_player() > attack_range * 1.2:
		_transition(EnemyState.FOLLOW)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("Death")
	sprite.animation_finished.connect(_on_death_animation_finished)


func _on_death_animation_finished() -> void:
	queue_free()


func _transition(new_state: EnemyState) -> void:
	if new_state == current_state:
		return


	current_state = new_state
	match current_state:
		EnemyState.IDLE:
			_enter_idle()
		EnemyState.FOLLOW:
			_enter_follow()
		EnemyState.ATTACK:
			_enter_attack()


# Animations
func _play_walk_or_idle_anim(vel: Vector2, idle_prefix: String) -> void:
	var walk_prefix := "Walk"

	if vel.length() < 1.0:
		_play_directional(idle_prefix)
	else:
		_play_directional(walk_prefix, vel)


var _last_dir : Vector2 = Vector2.DOWN

func _play_directional(prefix: String, dir: Vector2 = Vector2.ZERO) -> void:
	if dir != Vector2.ZERO:
		_last_dir = dir

	var anim_name : String

	if abs(_last_dir.x) >= abs(_last_dir.y):
		sprite.flip_h = _last_dir.x < 0
		anim_name = prefix + "Right"
	elif _last_dir.y < 0:
		sprite.flip_h = false
		anim_name = prefix + "Up"
	else:
		sprite.flip_h = false
		anim_name = prefix + "Down"

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _play_attack_anim() -> void:
	if not player:
		return

	var dir := player.global_position - global_position
	var anim_name : String

	if abs(dir.x) >= abs(dir.y):
		sprite.flip_h = dir.x < 0
		anim_name = "AttackRight"
	elif dir.y < 0:
		sprite.flip_h = false
		anim_name = "AttackUp"
	else:
		sprite.flip_h = false
		anim_name = "AttackDown"

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _dist_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)
