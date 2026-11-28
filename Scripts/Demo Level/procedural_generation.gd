extends Node2D

signal spawning_done

@export var rock_scene:           PackedScene
@export var tree_scene:           PackedScene
@export var fence_scene:          PackedScene
@export var fence_vertical_scene: PackedScene

@export_group("Spawn Counts")
@export var rock_count:           int = 10
@export var tree_count:           int = 8
@export var fence_count:          int = 2
@export var fence_vertical_count: int = 2

# ── Placement rules ───────────────────────────────────────────────────────────
@export_group("Placement Rules")
## World bounds: objects will only appear within this rectangle.
@export var world_rect: Rect2 = Rect2(20, 20, 600, 320)
## Minimum pixel distance between any two spawned objects.
@export var min_distance_between_objects: float = 60.0
## Minimum pixel distance from the player spawn position.
@export var min_distance_from_player: float = 60.0
## Maximum placement attempts per object before giving up.
@export var max_attempts: int = 100
## Random seed (0 = use time-based seed for different results every run).
@export var random_seed: int = 0

# ── Rotation ──────────────────────────────────────────────────────────────────
@export_group("Randomisation")
## Allow random rotation of spawned objects.
@export var randomise_rotation: bool = false
## Allow slight random scale variation (±scale_variation factor).
@export var randomise_scale: bool = false
@export var scale_variation: float = 0.15

# ── Internal state ────────────────────────────────────────────────────────────
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _placed_positions: Array = []

## Position of the player node at startup; populated in _ready.
var _player_start: Vector2 = Vector2(-9999, -9999)


# Initialise the RNG, fetch the player's position, and spawn all objects
func _ready() -> void:
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()

	var players := get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player_start = (players[0] as Node2D).global_position

	_spawn_batch(rock_scene,           rock_count,           "Rocks")
	_spawn_batch(tree_scene,           tree_count,           "Trees")
	_spawn_batch(fence_scene,          fence_count,          "Fences")
	_spawn_batch(fence_vertical_scene, fence_vertical_count, "FencesVertical")

	spawning_done.emit()


# Create a container for object type and instantiate the given number of object at valid random positions
func _spawn_batch(scene: PackedScene, count: int, group_name: String) -> void:
	if scene == null:
		push_warning("ProceduralSpawner: scene for '%s' is not set." % group_name)
		return

	var container := Node2D.new()
	container.name = group_name
	add_child(container)

	var spawned := 0
	for _i in range(count):
		var pos := _find_valid_position()
		if pos == Vector2.INF:
			push_warning(
				"ProceduralSpawner: could not place object %d of %s after %d attempts."
				% [_i + 1, group_name, max_attempts]
			)
			continue

		var instance: Node2D = scene.instantiate()
		container.add_child(instance)
		instance.position = pos
		instance.add_to_group("navigation_obstacle")

		if randomise_rotation:
			instance.rotation = _rng.randf_range(0.0, TAU)

		if randomise_scale:
			var s := 1.0 + _rng.randf_range(-scale_variation, scale_variation)
			instance.scale = Vector2(s, s)

		_placed_positions.append(pos)
		spawned += 1

	# print("ProceduralSpawner: placed %d / %d %s." % [spawned, count, group_name])


# Search for a random position that has valid distance between objects; returns INF on failure.
func _find_valid_position() -> Vector2:
	for _attempt in range(max_attempts):
		var candidate := Vector2(
			_rng.randf_range(world_rect.position.x, world_rect.end.x),
			_rng.randf_range(world_rect.position.y, world_rect.end.y)
		)

		if candidate.distance_to(_player_start) < min_distance_from_player:
			continue

		var too_close := false
		for placed in _placed_positions:
			if candidate.distance_to(placed) < min_distance_between_objects:
				too_close = true
				break

		if not too_close:
			return candidate

	return Vector2.INF
