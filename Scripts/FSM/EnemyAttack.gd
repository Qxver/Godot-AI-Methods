extends State
class_name EnemyAttack

@export var enemy: CharacterBody2D

var player: CharacterBody2D


func Enter():
	%EnemySprite.texture = preload("res://Assets/enemy_attack.png")
	enemy.velocity = Vector2.ZERO
	player = get_tree().get_first_node_in_group("Player")


func Physics_Update(_delta: float):
	if not player:
		return

	var direction = player.global_position - enemy.global_position

	if direction.length() > 35:
		Transitioned.emit(self, "Follow")
