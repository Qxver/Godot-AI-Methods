extends GutTest
## Tests for EnemyIdle state (res://Scripts/FSM/EnemyIdle.gd)
##
## EnemyIdle wanders randomly and transitions to "Follow" when
## the player comes within 100 px.


# ── Stubs ─────────────────────────────────────────────────────────────────────

class StubEnemy extends CharacterBody2D:
	pass

class StubPlayer extends CharacterBody2D:
	func _init() -> void:
		add_to_group("Player")


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _idle:   EnemyIdle
var _enemy:  StubEnemy
var _player: StubPlayer


func before_each() -> void:
	_enemy  = StubEnemy.new()
	_player = StubPlayer.new()

	# EnemyIdle reads player from the "Player" group in Enter();
	# add both to the tree so get_tree() works.
	add_child_autofree(_enemy)
	add_child_autofree(_player)

	_idle       = EnemyIdle.new()
	_idle.enemy = _enemy
	_idle.name  = "Idle"
	_enemy.add_child(_idle)   # realistic parent so %EnemySprite lookups don't crash

	# We skip calling Enter() in most tests to avoid the preload("%EnemySprite")
	# unique-name lookup – that requires the full scene.  Tested separately.


# ── randomize_wander ──────────────────────────────────────────────────────────

func test_randomize_wander_sets_normalized_direction() -> void:
	_idle.randomize_wander()
	var len := _idle.move_direction.length()
	assert_almost_eq(len, 1.0, 0.001,
		"move_direction should be normalized after randomize_wander()")


func test_randomize_wander_sets_positive_wander_time() -> void:
	_idle.randomize_wander()
	assert_gt(_idle.wander_time, 0.0,
		"wander_time should be > 0 after randomize_wander()")


func test_randomize_wander_time_within_range() -> void:
	for _i in range(20):
		_idle.randomize_wander()
		assert_between(_idle.wander_time, 1.0, 3.0,
			"wander_time must be between 1 and 3")


# ── Update: wander timer countdown ───────────────────────────────────────────

func test_update_decrements_wander_time() -> void:
	_idle.randomize_wander()
	var before := _idle.wander_time
	_idle.Update(0.1)
	assert_lt(_idle.wander_time, before,
		"Update() should decrement wander_time")


func test_update_re_randomizes_when_timer_expires() -> void:
	_idle.wander_time = 0.05
	var old_dir := _idle.move_direction
	# Exhaust the timer
	_idle.Update(0.1)
	# After expiry randomize_wander() is called; direction may differ
	# (not guaranteed by RNG, but wander_time must be reset > 0)
	assert_gt(_idle.wander_time, 0.0,
		"wander_time should be reset after timer expires")


# ── Transition thresholds ─────────────────────────────────────────────────────

func test_no_transition_when_player_far_away() -> void:
	watch_signals(_idle)
	_idle.player  = _player
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(200, 0)   # > 100 px away
	_idle.Physics_Update(0.016)
	assert_signal_not_emitted(_idle, "Transitioned",
		"Should NOT transition when player distance > 100")


func test_transition_to_follow_when_player_near() -> void:
	watch_signals(_idle)
	_idle.player  = _player
	_enemy.global_position  = Vector2(0, 0)
	_player.global_position = Vector2(50, 0)    # < 100 px
	_idle.Physics_Update(0.016)
	assert_signal_emitted_with_parameters(_idle, "Transitioned", [_idle, "Follow"])
