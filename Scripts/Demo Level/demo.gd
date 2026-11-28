extends Node2D

@onready var nav_region : NavigationRegion2D = $NavigationRegion2D


# Configures the navigation polygon and initiates navigation mesh baking
func _ready() -> void:
	var nav_poly := nav_region.navigation_polygon
	nav_poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_poly.source_geometry_group_name = "navigation_obstacle"

	var world_border := $WorldBorder
	if world_border:
		world_border.add_to_group("navigation_obstacle")

	_bake_deferred()


# Bake navigation polygon
func _bake_deferred() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_region.bake_navigation_polygon()


# Return to main menu button
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
