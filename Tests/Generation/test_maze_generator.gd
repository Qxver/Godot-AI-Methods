extends GutTest
## Tests for MazeGenerator (res://Scripts/Generation/maze_generator.gd)
##
## We load the script directly and drive it without a TileMapLayer so
## we can test pure data logic (maze array) independently of rendering.


# ── Minimal TileMapLayer stub ─────────────────────────────────────────────────

class StubTileMap extends Node2D:
	var cells := {}

	func clear() -> void:
		cells.clear()

	func set_cell(_coords: Vector2i, _source: int, _atlas: Vector2i) -> void:
		cells[_coords] = _atlas

	func map_to_local(cell: Vector2i) -> Vector2:
		# Simple 1:1 mapping for test purposes
		return Vector2(cell.x * 32.0, cell.y * 32.0)


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _gen:      Node2D
var _tilemap:  StubTileMap

const ROWS := 40
const COLS := 20


func before_each() -> void:
	_gen = Node2D.new()
	_gen.set_script(load("res://Scripts/Generation/maze_generator.gd"))

	_tilemap      = StubTileMap.new()
	_tilemap.name = "TileMapLayer"
	_gen.add_child(_tilemap)

	add_child_autofree(_gen)
	# _ready() is called automatically; maze is generated.


# ── Maze dimensions ───────────────────────────────────────────────────────────

func test_maze_has_correct_number_of_rows() -> void:
	assert_eq(_gen.maze.size(), ROWS,
		"Maze should have %d rows" % ROWS)


func test_maze_rows_have_correct_number_of_cols() -> void:
	for row in _gen.maze:
		assert_eq(row.size(), COLS,
			"Each maze row should have %d columns" % COLS)


# ── Border is always wall (value 0) ──────────────────────────────────────────

func test_top_border_is_wall() -> void:
	for c in range(COLS):
		assert_eq(_gen.maze[0][c], 0,
			"Top border cell [0][%d] should be a wall" % c)


func test_bottom_border_is_wall() -> void:
	for c in range(COLS):
		assert_eq(_gen.maze[ROWS - 1][c], 0,
			"Bottom border cell [%d][%d] should be a wall" % [ROWS - 1, c])


func test_left_border_is_wall() -> void:
	for r in range(ROWS):
		assert_eq(_gen.maze[r][0], 0,
			"Left border cell [%d][0] should be a wall" % r)


func test_right_border_is_wall() -> void:
	for r in range(ROWS):
		assert_eq(_gen.maze[r][COLS - 1], 0,
			"Right border cell [%d][%d] should be a wall" % [r, COLS - 1])


# ── Start cell is always open ─────────────────────────────────────────────────

func test_start_cell_is_open() -> void:
	assert_eq(_gen.maze[1][1], 0,
		"Start cell [1][1] should be open (0 = wall in this scheme)")


# ── Values are only 0 or 1 ───────────────────────────────────────────────────

func test_maze_contains_only_valid_values() -> void:
	for row in _gen.maze:
		for cell in row:
			assert_true(cell == 0 or cell == 1,
				"All maze values must be 0 or 1, got: %d" % cell)


# ── Regeneration ─────────────────────────────────────────────────────────────

func test_generate_maze_emits_maze_generated_signal() -> void:
	watch_signals(_gen)
	_gen.generate_maze()
	assert_signal_emitted(_gen, "maze_generated",
		"generate_maze() should emit 'maze_generated'")


func test_reset_maze_fills_with_walls() -> void:
	# After reset, all cells should be 1 (wall/unvisited)
	_gen.reset_maze()
	for row in _gen.maze:
		for cell in row:
			assert_eq(cell, 1,
				"After reset_maze() every cell should be 1")


# ── get_random_open_cell ──────────────────────────────────────────────────────

func test_get_random_open_cell_returns_vector2() -> void:
	var result = _gen.get_random_open_cell()
	assert_true(result is Vector2,
		"get_random_open_cell() should return a Vector2")


func test_get_random_open_cell_returns_zero_on_empty_maze() -> void:
	# Force all cells to 0 (walls) so open_cells list is empty
	_gen.reset_maze()
	for r in range(ROWS):
		for c in range(COLS):
			_gen.maze[r][c] = 0
	var result = _gen.get_random_open_cell()
	assert_eq(result, Vector2.ZERO,
		"Should return Vector2.ZERO when no open cells exist")
