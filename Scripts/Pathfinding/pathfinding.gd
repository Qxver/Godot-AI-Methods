extends Node2D

@onready var maze_generator = $MazeGenerator
@onready var player = $Player
@onready var enemy = $Enemy

func _ready() -> void:
	var mg_player = maze_generator.get_node_or_null("Player")
	if mg_player:
		mg_player.queue_free()

	var mg_canvas = maze_generator.get_node_or_null("CanvasLayer")
	if mg_canvas:
		mg_canvas.visible = false

func _on_randomize_button_pressed() -> void:
	maze_generator.generate_maze()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
