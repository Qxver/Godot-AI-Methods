extends GutTest
## Tests for ProceduralSpawner (res://Scripts/Demo Level/procedural_generation.gd)
##
## We test the pure-logic helpers (_find_valid_position, placement rules)
## without spawning real scenes, by driving the spawner's internal state.


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _spawner: Node2D


func before_each() -> void:
	_spawner = Node2D.new()
	_spawner.set_script(load("res://Scripts/Demo Level/procedural_generation.gd"))
	# Do NOT add to tree here — we set scenes to null so _ready won't spawn
	_spawner.rock_scene           = null
	_spawner.tree_scene           = null
	_spawner.fence_scene          = null
	_spawner.fence_vertical_scene = null
	add_child_autofree(_spawner)


# ── Default export values ─────────────────────────────────────────────────────

func test_default_world_rect_is_set() -> void:
	assert_eq(_spawner.world_rect, Rect2(20, 20, 600, 320),
		"Default world_rect should be Rect2(20, 20, 600, 320)")


func test_default_min_distance_between_objects() -> void:
	assert_eq(_spawner.min_distance_between_objects, 60.0,
		"Default min_distance_between_objects should be 60.0")


func test_default_min_distance_from_player() -> void:
	assert_eq(_spawner.min_distance_from_player, 60.0,
		"Default min_distance_from_player should be 60.0")


func test_default_max_attempts() -> void:
	assert_eq(_spawner.max_attempts, 100,
		"Default max_attempts should be 100")


# ── _find_valid_position ──────────────────────────────────────────────────────

func test_find_valid_position_returns_vector2() -> void:
	var pos = _spawner._find_valid_position()
	assert_true(pos is Vector2,
		"_find_valid_position should return a Vector2")


func test_find_valid_position_within_world_rect() -> void:
	for _i in range(20):
		var pos = _spawner._find_valid_position()
		if pos == Vector2.INF:
			continue   # skip failed attempts
		assert_true(_spawner.world_rect.has_point(pos),
			"Placed position %s must be inside world_rect" % pos)


func test_find_valid_position_respects_min_distance() -> void:
	_spawner._placed_positions = [Vector2(100, 100)]
	_spawner.min_distance_between_objects = 50.0

	for _i in range(30):
		var pos = _spawner._find_valid_position()
		if pos == Vector2.INF:
			continue
		var too_close := false
		for placed in _spawner._placed_positions:
			if pos.distance_to(placed) < _spawner.min_distance_between_objects:
				too_close = true
		assert_false(too_close,
			"Placed position must respect min_distance_between_objects")


func test_find_valid_position_respects_player_exclusion_zone() -> void:
	_spawner._player_start = Vector2(200, 200)
	_spawner.min_distance_from_player = 60.0

	for _i in range(30):
		var pos = _spawner._find_valid_position()
		if pos == Vector2.INF:
			continue
		assert_gte(pos.distance_to(_spawner._player_start),
			_spawner.min_distance_from_player,
			"Placed position must be outside player exclusion zone")


func test_find_valid_position_returns_inf_when_impossible() -> void:
	# Fill the placed list with a dense grid so no valid spot exists
	_spawner.min_distance_between_objects = 999.0
	_spawner._placed_positions = [Vector2(320, 180)]  # centre of world
	var result = _spawner._find_valid_position()
	assert_eq(result, Vector2.INF,
		"Should return Vector2.INF when no valid position can be found")


# ── Determinism with fixed seed ───────────────────────────────────────────────

func test_fixed_seed_produces_same_positions() -> void:
	_spawner.random_seed = 42
	_spawner._rng.seed = 42
	var first: Vector2 = _spawner._find_valid_position()

	_spawner._rng.seed = 42
	var second: Vector2 = _spawner._find_valid_position()

	assert_eq(first, second,
		"Same RNG seed should produce identical positions")
