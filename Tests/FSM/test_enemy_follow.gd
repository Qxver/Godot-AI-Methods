extends GutTest
## Tests for EnemyFollow state (res://Scripts/FSM/EnemyFollow.gd)
##
## EnemyFollow chases the player and transitions:
##   • → Idle   when distance > 150 px
##   • → Attack  when distance < 32 px


# ── Stubs ─────────────────────────────────────────────────────────────────────

class StubEnemy extends CharacterBody2D:
	pass

class StubPlayer extends CharacterBody2D:
	pass


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _follow: EnemyFollow
var _enemy:  StubEnemy
var _player: StubPlayer


func before_each() -> void:
	_enemy  = StubEnemy.new()
	_player = StubPlayer.new()
	add_child_autofree(_enemy)
	add_child_autofree(_player)

	_follow        = EnemyFollow.new()
	_follow.enemy  = _enemy
	_follow.player = _player
	_enemy.add_child(_follow)


# ── Velocity ──────────────────────────────────────────────────────────────────

func test_moves_toward_player_when_far() -> void:
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(100, 0)
	_follow.Physics_Update(0.016)
	assert_gt(_enemy.velocity.x, 0.0,
		"Enemy should move in positive-x direction toward the player")


func test_velocity_zero_when_at_player_position() -> void:
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(3, 0)   # distance < 5 → stop
	_follow.Physics_Update(0.016)
	assert_eq(_enemy.velocity, Vector2.ZERO,
		"Enemy velocity should be zero when overlapping player")


func test_velocity_magnitude_matches_move_speed() -> void:
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(100, 0)
	_follow.Physics_Update(0.016)
	assert_almost_eq(_enemy.velocity.length(), _follow.move_speed, 0.1,
		"Velocity magnitude should equal move_speed")


# ── Transitions ───────────────────────────────────────────────────────────────

func test_no_transition_when_in_follow_range() -> void:
	watch_signals(_follow)
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(80, 0)   # 32 < d < 150
	_follow.Physics_Update(0.016)
	assert_signal_not_emitted(_follow, "Transitioned",
		"No transition expected when distance is in follow range")


func test_transition_to_idle_when_player_too_far() -> void:
	watch_signals(_follow)
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(200, 0)  # > 150
	_follow.Physics_Update(0.016)
	assert_signal_emitted_with_parameters(_follow, "Transitioned", [_follow, "Idle"])


func test_transition_to_attack_when_player_very_close() -> void:
	watch_signals(_follow)
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(20, 0)   # < 32
	_follow.Physics_Update(0.016)
	assert_signal_emitted_with_parameters(_follow, "Transitioned", [_follow, "Attack"])
