extends Node2D

@onready var nav_region : NavigationRegion2D = $NavigationRegion2D


func _ready() -> void:
	# Konfigurujemy NavigationPolygon tak, żeby bake skanował
	# węzły należące do grupy "navigation_obstacle" zamiast
	# dzieci NavigationRegion2D (które są puste).
	var nav_poly := nav_region.navigation_polygon
	nav_poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_poly.source_geometry_group_name = "navigation_obstacle"

	# WorldBorder jest zdefiniowany bezpośrednio w scenie –
	# dodajemy go do grupy ręcznie.
	var world_border := $WorldBorder
	if world_border:
		world_border.add_to_group("navigation_obstacle")

	# ProceduralSpawner._ready() wywołuje się PRZED Demo._ready()
	# (Godot uruchamia _ready() od dzieci do rodziców), więc obiekty
	# są już w drzewie. Czekamy na dwie klatki fizyki żeby
	# PhysicsServer2D zdążył zarejestrować ich CollisionShape2D.
	_bake_deferred()


func _bake_deferred() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_region.bake_navigation_polygon()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
