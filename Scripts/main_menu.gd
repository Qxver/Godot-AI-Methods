extends Control



func _on_fsm_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/FSM/fsm_patrol.tscn")
	

func _on_pathfinding_button_pressed() -> void:
		get_tree().change_scene_to_file("res://Scenes/Pathfinding/pathfinding.tscn")
		
		
func _on_generation_button_pressed() -> void:
		pass
