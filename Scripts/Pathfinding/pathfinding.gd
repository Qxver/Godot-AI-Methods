extends Node2D

var maze_generator: Node
var player: Node
var enemy: Node

func _ready() -> void:
	maze_generator = get_node_or_null("MazeGenerator")
	player         = get_node_or_null("Player")
	enemy          = get_node_or_null("Enemy")

	if not maze_generator:
		return

	var mg_player = maze_generator.get_node_or_null("Player")
	if mg_player:
		mg_player.queue_free()

	var mg_canvas = maze_generator.get_node_or_null("CanvasLayer")
	if mg_canvas:
		mg_canvas.visible = false

func _on_randomize_button_pressed() -> void:
	if maze_generator:
		maze_generator.generate_maze()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
