extends GutTest
## Tests for StateMachine (res://Scripts/FSM/StateMachine.gd)
##
## Strategy: build a minimal scene tree with a StateMachine and two stub
## State nodes so we can exercise transitions without needing a real enemy.

# ── Helpers / stubs ───────────────────────────────────────────────────────────

class StubState extends State:
	var entered  := false
	var exited   := false
	var name_id  := ""

	func Enter()  -> void: entered = true
	func Exit()   -> void: exited  = true


# ── Fixtures ──────────────────────────────────────────────────────────────────

var _sm:    Node       # StateMachine instance loaded from script
var _idle:  StubState
var _follow: StubState


func before_each() -> void:
	var sm_script = load("res://Scripts/FSM/StateMachine.gd")
	_sm = Node.new()
	_sm.set_script(sm_script)
	add_child_autofree(_sm)

	_idle        = StubState.new()
	_idle.name   = "Idle"
	_follow      = StubState.new()
	_follow.name = "Follow"

	_sm.add_child(_idle)
	_sm.add_child(_follow)
	_sm.initial_state = _idle

	# Manually trigger _ready logic after the tree is set up
	_sm._ready()


# ── Initialisation ────────────────────────────────────────────────────────────

func test_initial_state_is_entered_on_ready() -> void:
	assert_true(_idle.entered, "Initial state Enter() should be called on _ready")


func test_current_state_is_set_to_initial_state() -> void:
	assert_eq(_sm.current_state, _idle,
		"current_state should equal initial_state after _ready")


func test_states_dictionary_populated() -> void:
	assert_true(_sm.states.has("idle"),   "states dict should contain 'idle'")
	assert_true(_sm.states.has("follow"), "states dict should contain 'follow'")


# ── Transition ────────────────────────────────────────────────────────────────

func test_valid_transition_changes_current_state() -> void:
	_idle.Transitioned.emit(_idle, "Follow")
	assert_eq(_sm.current_state, _follow,
		"After transition to Follow, current_state should be _follow")


func test_valid_transition_calls_exit_on_old_state() -> void:
	_idle.Transitioned.emit(_idle, "Follow")
	assert_true(_idle.exited, "Old state Exit() should be called on transition")


func test_valid_transition_calls_enter_on_new_state() -> void:
	_idle.Transitioned.emit(_idle, "Follow")
	assert_true(_follow.entered, "New state Enter() should be called on transition")


func test_transition_from_non_current_state_is_ignored() -> void:
	# _follow is not current_state; signal from it should be ignored
	_follow.Transitioned.emit(_follow, "Idle")
	assert_eq(_sm.current_state, _idle,
		"Transition from a non-active state must be ignored")


func test_transition_to_unknown_state_is_ignored() -> void:
	_idle.Transitioned.emit(_idle, "NonExistent")
	assert_eq(_sm.current_state, _idle,
		"Transition to an unknown state name must be ignored")


# ── Update delegation ─────────────────────────────────────────────────────────

func test_process_delegates_to_current_state() -> void:
	# StubState has no Update override → just ensure no crash
	_sm._process(0.016)
	pass_test("_process delegates to current_state without error")


func test_physics_process_delegates_to_current_state() -> void:
	_sm._physics_process(0.016)
	pass_test("_physics_process delegates to current_state without error")
