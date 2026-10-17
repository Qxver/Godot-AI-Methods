extends Node2D

signal maze_generated

@onready var tileMap = $TileMapLayer

const ROWS = 40
const COLS = 20
const WALL = Vector2i(0, 0)
const PATH = Vector2i(1, 0)

var maze = []

func _ready() -> void:
	reset_maze()
	generate_maze()
	
	
func reset_maze():
	maze = []
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(1)
		maze.append(row)
	

func generate_maze():
	reset_maze()
	
	var start_row = 1
	var start_col = 1
	maze[start_row][start_col] = 0
	
	make_path(start_row, start_col)
	draw_maze()
	emit_signal("maze_generated")
	

func make_path(row, col):
	var directions = [
		[-2, 0], # up
		[0, 2], # right
		[2, 0], # down
		[0, -2] # left
	]
	
	directions.shuffle()
	
	for direction in directions:
		var direction_row = direction[0]
		var direction_col = direction[1]
		
		var new_row = row + direction_row
		var new_col = col + direction_col
		
		if (new_row > 0 and new_row < ROWS - 1 and
			new_col > 0 and new_col < COLS - 1 and
			maze[new_row][new_col] == 1
		):
			maze[new_row][new_col] = 0
			maze[row + direction_row / 2][col + direction_col / 2] = 0
			
			make_path(new_row, new_col)
		

	
func draw_maze():
	tileMap.clear()
	
	for row in range(ROWS):
		for col in range(COLS):
			var tile_type = WALL if maze[row][col] == 0 else PATH
			tileMap.set_cell(Vector2i(row, col), 0, tile_type)


func get_random_open_cell() -> Vector2:
	var open_cells: Array[Vector2i] = []
	for row in range(ROWS):
		for col in range(COLS):
			if maze[row][col] == 1:
				open_cells.append(Vector2i(row, col))
	if open_cells.is_empty():
		return Vector2.ZERO
	var cell = open_cells[randi() % open_cells.size()]
	return tileMap.map_to_local(cell)


func _on_randomize_button_pressed() -> void:
	generate_maze()
	

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
