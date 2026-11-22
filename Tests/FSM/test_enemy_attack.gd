extends GutTest
## Tests for EnemyAttack state (res://Scripts/FSM/EnemyAttack.gd)
##
## EnemyAttack halts enemy movement and transitions → Follow when
## distance > 35 px.


# ── Stubs ─────────────────────────────────────────────────────────────────────

class StubEnemy extends CharacterBody2D:
	pass

class StubPlayer extends CharacterBody2D:
	pass


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _attack: EnemyAttack
var _enemy:  StubEnemy
var _player: StubPlayer


func before_each() -> void:
	_enemy  = StubEnemy.new()
	_player = StubPlayer.new()
	add_child_autofree(_enemy)
	add_child_autofree(_player)

	_attack        = EnemyAttack.new()
	_attack.enemy  = _enemy
	_attack.player = _player
	_enemy.add_child(_attack)


# ── No crash when player is null ──────────────────────────────────────────────

func test_physics_update_safe_when_player_null() -> void:
	_attack.player = null
	_attack.Physics_Update(0.016)
	pass_test("Physics_Update with null player should not crash")


# ── Transitions ───────────────────────────────────────────────────────────────

func test_no_transition_when_player_within_attack_range() -> void:
	watch_signals(_attack)
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(20, 0)   # < 35
	_attack.Physics_Update(0.016)
	assert_signal_not_emitted(_attack, "Transitioned",
		"Should NOT transition when player is within attack range (< 35 px)")


func test_transition_to_follow_when_player_out_of_range() -> void:
	watch_signals(_attack)
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(50, 0)   # > 35
	_attack.Physics_Update(0.016)
	assert_signal_emitted_with_parameters(_attack, "Transitioned", [_attack, "Follow"])
