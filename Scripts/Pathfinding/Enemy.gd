extends CharacterBody2D

@export var speed: float = 50.0
@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D

func _ready() -> void:
	make_path()

func _physics_process(_delta: float) -> void:
	if not player:
		return
		
	if nav_agent.is_navigation_finished():
		return
		
	var direction = to_local(nav_agent.get_next_path_position()).normalized()
	velocity = direction * speed
	move_and_slide()

func make_path() -> void:
	if player:
		nav_agent.target_position = player.global_position

func _on_timer_timeout() -> void:
	make_path()
