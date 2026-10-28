extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * 100.0
	move_and_slide()

	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		_play_idle_animation()
	else:
		last_direction = direction
		_play_walk_animation(direction)

func _play_walk_animation(direction: Vector2) -> void:
	if abs(direction.x) >= abs(direction.y):
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play("WalkRight")
	elif direction.y < 0:
		animated_sprite.flip_h = false
		animated_sprite.play("WalkUp")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("WalkDown")

func _play_idle_animation() -> void:
	if abs(last_direction.x) >= abs(last_direction.y):
		animated_sprite.flip_h = last_direction.x < 0
		animated_sprite.play("IdleRight")
	elif last_direction.y < 0:
		animated_sprite.flip_h = false
		animated_sprite.play("IdleUp")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("Idle")
