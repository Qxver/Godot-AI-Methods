extends GutTest
## Tests for the base State class (res://Scripts/FSM/State.gd)

var _state: State


func before_each() -> void:
	_state = State.new()
	add_child_autofree(_state)


# ── Signal ────────────────────────────────────────────────────────────────────

func test_state_has_transitioned_signal() -> void:
	assert_true(_state.has_signal("Transitioned"),
		"State should expose the 'Transitioned' signal")


func test_transitioned_signal_emits_with_correct_args() -> void:
	watch_signals(_state)
	_state.Transitioned.emit(_state, "Follow")
	assert_signal_emitted_with_parameters(_state, "Transitioned", [_state, "Follow"])


# ── Default method stubs ──────────────────────────────────────────────────────

func test_enter_does_not_crash() -> void:
	# Base Enter() is a no-op; just confirm it runs without error.
	_state.Enter()
	pass_test("Enter() ran without error")


func test_exit_does_not_crash() -> void:
	_state.Exit()
	pass_test("Exit() ran without error")


func test_update_does_not_crash() -> void:
	_state.Update(0.016)
	pass_test("Update() ran without error")


func test_physics_update_does_not_crash() -> void:
	_state.Physics_Update(0.016)
	pass_test("Physics_Update() ran without error")
