extends Node

signal rewards_applied(reward_packet: Dictionary)
signal rewards_ready(rewards: Dictionary)

var streak_multiplier := 1.0
var difficulty_multiplier := 1.0

func process_memory_rewards(stats: Dictionary) -> void:
	var base = _calculate_base_rewards(stats)
	var modifiers = _calculate_modifiers(stats)

	var final_rewards = {
		"coins": int(base["coins"] * modifiers["total"]),
		"eggs": int(base["eggs"] * modifiers["total"]),
		"xp": int(base["xp"] * modifiers["total"]),
		"perfect": modifiers["perfect"]
	}

	emit_signal("rewards_ready", final_rewards)

func _calculate_base_rewards(stats: Dictionary) -> Dictionary:
	var grid_size: Vector2i = stats.get("grid", Vector2i(2, 2))
	var total_cells = grid_size.x * grid_size.y

	var coins = total_cells * 2
	var eggs = 1
	var xp = total_cells

	return {
		"coins": coins,
		"eggs": eggs,
		"xp": xp
	}

func _calculate_modifiers(stats: Dictionary) -> Dictionary:
	var modifier = 1.0
	var perfect = false

	var grid_size: Vector2i = stats.get("grid", Vector2i(2, 2))
	var total_cells = grid_size.x * grid_size.y

	if stats.get("moves", 0) <= total_cells:
		modifier += 0.5
		perfect = true

	if stats.get("time", 0.0) < 20.0:
		modifier += 0.3

	modifier += streak_multiplier
	modifier += difficulty_multiplier * 0.2

	return {
		"total": clamp(modifier, 1.0, 3.0),
		"perfect": perfect
	}

func increase_streak() -> void:
	streak_multiplier = min(streak_multiplier + 0.1, 1.5)

func reset_streak() -> void:
	streak_multiplier = 1.0

func set_difficulty(level: int) -> void:
	difficulty_multiplier = 1.0 + (level * 0.1)

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)

func apply_rewards(reward_packet: Dictionary) -> void:
	SaveSystem.add_rewards(reward_packet)
	
	GameState.session_rewards = reward_packet
	rewards_applied.emit(reward_packet)
	_emit_juice("reward_granted", reward_packet)
