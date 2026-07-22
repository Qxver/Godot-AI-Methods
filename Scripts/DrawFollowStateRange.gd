extends Area2D

@export var detection_radius: float = 100.0
@export var follow_radius: float = 150.0
@export var detection_color: Color = Color(1, 1, 0, 0.5)
@export var follow_color: Color = Color(1, 0, 0, 0.5)
@export var line_width: float = 2.0

func _draw() -> void:
	draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, detection_color, line_width)
	draw_arc(Vector2.ZERO, follow_radius, 0, TAU, 64, follow_color, line_width)
