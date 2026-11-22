extends GutTest
## Integration test for Demo scene back-button script
## (res://Scripts/Demo Level/demo.gd)
##
## demo.gd only contains _on_pressed() which calls get_tree().change_scene_to_file().
## We verify the script loads and that the method exists; a full scene-change
## test would require a running SceneTree which GUT provides via add_child.


func test_demo_script_loads() -> void:
	var script = load("res://Scripts/Demo Level/demo.gd")
	assert_not_null(script, "demo.gd should load without error")


func test_demo_script_has_on_pressed_method() -> void:
	var script = load("res://Scripts/Demo Level/demo.gd")
	var node   = Button.new()
	node.set_script(script)
	add_child_autofree(node)
	assert_true(node.has_method("_on_pressed"),
		"demo.gd should define _on_pressed()")
