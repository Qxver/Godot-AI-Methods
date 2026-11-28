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

@export var attack_damage  : int   = 10
@export var attack_cooldown: float = 1.0
@export var max_hp         : int   = 50

@onready var sprite     : AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar : ProgressBar      = $HealthBar
@onready var nav_agent  : NavigationAgent2D = $NavigationAgent2D

var current_hp : int

var _hit_flash_timer  : float = 0.0
const HIT_FLASH_DURATION : float = 0.15

enum EnemyState { IDLE, FOLLOW, ATTACK, DEATH }

var current_state : EnemyState = EnemyState.IDLE
var player        : CharacterBody2D

var wander_direction : Vector2
var wander_timer     : float
var pause_timer      : float = 0.0
var is_pausing       : bool  = false

var is_dead : bool = false

var _attack_timer: float = 0.0


# Initialize enemy stats, health bar and animation
func _ready() -> void:
	current_hp = max_hp
	add_to_group("Enemy")
	health_bar.max_value = max_hp
	health_bar.value     = max_hp
	sprite.sprite_frames.set_animation_loop("Death", false)
	player = get_tree().get_first_node_in_group("Player")
	sprite.play("IdleDown")
	_enter_idle()


# Update hit-flash effect, check for death, run current state actions
func _physics_process(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

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


# Enters the idle state by starting a pause before the next wander
func _enter_idle() -> void:
	_start_pause()


# Stops the enemy and starts a random pause timer.
func _start_pause() -> void:
	is_pausing       = true
	pause_timer      = randf_range(pause_min_time, pause_max_time)
	wander_direction = Vector2.ZERO


# Picks a random direction and wander duration, leaving the pause state.
func _start_wander() -> void:
	is_pausing       = false
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer     = randf_range(wander_min_time, wander_max_time)


# Alternates between pausing and wandering; change state to FOLLOW when the player is detected
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

		_play_animation(velocity, "Idle")

	if player and _dist_to_player() < detect_range:
		_transition(EnemyState.FOLLOW)


# Enter FOLLOW state by refreshing the navigation path to the player
func _enter_follow() -> void:
	_refresh_nav_path()


# Updates navigation agent target to the player current position
func _refresh_nav_path() -> void:
	if player:
		nav_agent.target_position = player.global_position


# Move enemy towards the player; switches state to IDLE or ATTACK when player is too far or too close
func _update_follow(delta: float) -> void:
	if not player:
		_transition(EnemyState.IDLE)
		return

	var dist := _dist_to_player()

	if dist > lose_range:
		_transition(EnemyState.IDLE)
		return
	elif dist < attack_range:
		_transition(EnemyState.ATTACK)
		return

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_pos := nav_agent.get_next_path_position()
		var dir := to_local(next_pos).normalized()
		velocity = dir * chase_speed

	_play_animation(velocity, "Idle")


# Stops movement and plays the attack animation upon entering the ATTACK state
func _enter_attack() -> void:
	velocity = Vector2.ZERO
	_play_attack_animation()




# Deals damage to the player every cooldown interval; returns to FOLLOW when the player moves away
func _update_attack(delta: float) -> void:
	if not player:
		_transition(EnemyState.IDLE)
		return

	velocity = Vector2.ZERO

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

	if _dist_to_player() > attack_range * 1.2:
		_transition(EnemyState.FOLLOW)



# Subtracts HP, triggers the hit-flash effect, and dies at 0 HP
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp -= amount
	current_hp = max(current_hp, 0)
	health_bar.value = current_hp

	sprite.modulate = Color(1.0, 0.25, 0.25)
	_hit_flash_timer = HIT_FLASH_DURATION

	if current_hp <= 0:
		die()


# Mark the enemy as dead, play death animation
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.play("Death")
	if not sprite.animation_finished.is_connected(_on_death_animation_finished):
		sprite.animation_finished.connect(_on_death_animation_finished)


# Removes the enemy node 5 seconds after the death animation finishes
func _on_death_animation_finished() -> void:
	await get_tree().create_timer(5.0).timeout
	queue_free()


# Refreshes the navigation path while the enemy is in the FOLLOW state
func _on_nav_timer_timeout() -> void:
	if current_state == EnemyState.FOLLOW:
		_refresh_nav_path()


# Changes the state machine state
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


# Select a walk or idle animation based on the current velocity
func _play_animation(vel: Vector2, idle_prefix: String) -> void:
	var walk_prefix := "Walk"

	if vel.length() < 1.0:
		_play_directional(idle_prefix)
	else:
		_play_directional(walk_prefix, vel)


var _last_dir : Vector2 = Vector2.DOWN

# Plays a directional animation based on last movement direction
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


# Plays the attack animation directed toward the player
func _play_attack_animation() -> void:
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


# Returns the distance to the player, or INF if the player does not exist
func _dist_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)
