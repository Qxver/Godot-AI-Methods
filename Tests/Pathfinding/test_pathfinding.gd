extends GutTest
## Tests for pathfinding.gd (res://Scripts/Pathfinding/pathfinding.gd)
##
## pathfinding.gd is a thin coordinator that:
##   1. Hides the maze generator's player/canvas on _ready.
##   2. Calls maze_generator.generate_maze() on button press.
##   3. Changes scene on back button press.
##
## We verify the script loads and exposes the expected methods.
## Full integration (MazeGenerator + NavigationAgent2D) is covered in
## test_maze_generator.gd.


func test_pathfinding_script_loads() -> void:
	var script = load("res://Scripts/Pathfinding/pathfinding.gd")
	assert_not_null(script, "pathfinding.gd should load without error")


func test_pathfinding_script_has_randomize_handler() -> void:
	var script = load("res://Scripts/Pathfinding/pathfinding.gd")
	var node   = Node2D.new()
	node.set_script(script)
	add_child_autofree(node)
	assert_true(node.has_method("_on_randomize_button_pressed"),
		"pathfinding.gd should define _on_randomize_button_pressed()")


func test_pathfinding_script_has_back_handler() -> void:
	var script = load("res://Scripts/Pathfinding/pathfinding.gd")
	var node   = Node2D.new()
	node.set_script(script)
	add_child_autofree(node)
	assert_true(node.has_method("_on_button_pressed"),
		"pathfinding.gd should define _on_button_pressed()")
