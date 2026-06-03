extends Control
## DebugPanel.gd
## UI for live tuning and simulation.

@onready var grid_x_slider: HSlider = %GridXSlider
@onready var grid_y_slider: HSlider = %GridYSlider
@onready var grid_label: Label = %GridLabel
@onready var navigation_state_label: Label = %NavigationStateLabel

@onready var coin_mul_slider: HSlider = %CoinMulSlider
@onready var coin_mul_label: Label = %CoinMulLabel

@onready var merge_egg_input: SpinBox = %MergeEggInput
@onready var merge_blob_input: SpinBox = %MergeBlobInput

@onready var sim_runs_input: LineEdit = %SimRunsInput
@onready var sim_output: TextEdit = %SimOutput

var _progression_simulator = load("res://systems/utils/progression_simulator.gd").new()
var _balancing_config = preload("res://resources/balancing/game_balancing.tres")

func _ready() -> void:
	# Memory Tab
	grid_x_slider.value_changed.connect(_on_grid_changed)
	grid_y_slider.value_changed.connect(_on_grid_changed)

	# Rewards Tab
	coin_mul_slider.value_changed.connect(_on_reward_mul_changed)

	# Merge Tab
	merge_egg_input.value_changed.connect(_on_merge_cost_changed.bind(1))
	merge_blob_input.value_changed.connect(_on_merge_cost_changed.bind(2))

	# Initial UI update
	_on_grid_changed(0)
	_on_reward_mul_changed(1.0)
	_update_navigation_state()

	if GameManager:
		GameManager.debug_state_changed.connect(_on_debug_state_changed)

func _on_grid_changed(_val: float) -> void:
	var x = int(grid_x_slider.value)
	var y = int(grid_y_slider.value)
	grid_label.text = "Grid Size: %dx%d" % [x, y]

	if has_node("/root/DebugTuner"):
		get_node("/root/DebugTuner").memory_grid_override = Vector2i(x, y)

func _on_reward_mul_changed(val: float) -> void:
	coin_mul_label.text = "Reward Multiplier: %.1fx" % val
	if has_node("/root/DebugTuner"):
		get_node("/root/DebugTuner").reward_multiplier = val

func _on_merge_cost_changed(val: float, stage: int) -> void:
	if has_node("/root/DebugTuner"):
		get_node("/root/DebugTuner").merge_cost_overrides[stage] = int(val)

func _on_run_sim_pressed() -> void:
	var runs_per_session = 5
	var sessions_per_day = 2
	var days = 7

	# Try to get values from UI if they exist (added for flexibility)
	var sim_days_input = get_node_or_null("%SimDaysInput")
	if sim_days_input and sim_days_input is SpinBox:
		days = int(sim_days_input.value)

	var result = _progression_simulator.run_simulation(_balancing_config, days, sessions_per_day, runs_per_session)
	sim_output.text = result

func _on_close_pressed() -> void:
	hide()

func _on_debug_state_changed(debug_text: String) -> void:
	if navigation_state_label:
		navigation_state_label.text = debug_text

func _update_navigation_state() -> void:
	if not navigation_state_label:
		return
	if GameManager:
		navigation_state_label.text = GameManager.get_debug_state_text()
	else:
		navigation_state_label.text = "Current State: Unknown"
