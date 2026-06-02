extends Node
## DebugTuner.gd
## Middleware for live overrides of game systems.

var memory_grid_override := Vector2i(-1, -1)
var reward_multiplier := 1.0
var egg_rate_override := -1
var merge_cost_overrides := {} # stage_index -> cost

var _debug_panel_scene = preload("res://scenes/debug/DebugPanel.tscn")
var _debug_panel_instance: Control = null

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	print("[DebugTuner] Ready (Debug Build)")

	# Create debug panel instance but keep hidden
	_debug_panel_instance = _debug_panel_scene.instantiate()
	get_tree().root.call_deferred("add_child", _debug_panel_instance)
	_debug_panel_instance.hide()

func _input(event: InputEvent) -> void:
	# Toggle via F3
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F3:
			_toggle_debug_panel()

	# Toggle via 3-finger tap on mobile
	if event is InputEventScreenTouch:
		if event.pressed:
			var touches = _get_active_touches(event)
			if touches >= 3:
				_toggle_debug_panel()

func _toggle_debug_panel() -> void:
	if _debug_panel_instance:
		_debug_panel_instance.visible = !_debug_panel_instance.visible
		if _debug_panel_instance.visible:
			_debug_panel_instance.move_to_front()

func _get_active_touches(_current_event: InputEventScreenTouch) -> int:
	# Simplified check: just count indices if possible, or use a custom tracker.
	# For now, we'll assume the system reports multi-touch correctly.
	# Godot's Input class can also track this.
	var count = 0
	# This is a bit tricky in Godot without a custom tracker,
	# but we can check Input.is_mouse_button_pressed if emulating touch.
	# A more robust way is to track touch indices in a Dictionary.
	return _touch_tracker.size()

var _touch_tracker = {}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_tracker[event.index] = event.position
			if _touch_tracker.size() >= 3:
				_toggle_debug_panel()
				_touch_tracker.clear() # Reset to avoid double triggers
		else:
			_touch_tracker.erase(event.index)

func set_memory_grid(x: int, y: int) -> void:
	memory_grid_override = Vector2i(x, y)
	print("[DebugTuner] Memory grid override: ", memory_grid_override)

func clear_overrides() -> void:
	memory_grid_override = Vector2i(-1, -1)
	reward_multiplier = 1.0
	egg_rate_override = -1
	merge_cost_overrides.clear()
	print("[DebugTuner] All overrides cleared")

# ── SYSTEM HOOKS ───────────────────────────────────────────────────────

func get_grid_size(base_grid: Vector2i) -> Vector2i:
	if memory_grid_override.x > 0 and memory_grid_override.y > 0:
		return memory_grid_override
	return base_grid

func apply_reward_multipliers(rewards: Dictionary) -> Dictionary:
	rewards["coins"] = int(rewards["coins"] * reward_multiplier)
	if egg_rate_override >= 0:
		rewards["eggs"] = egg_rate_override
	else:
		rewards["eggs"] = int(rewards["eggs"] * reward_multiplier)
	return rewards

func get_merge_cost(stage: int, base_cost: int) -> int:
	if merge_cost_overrides.has(stage):
		return int(merge_cost_overrides[stage])
	return base_cost
