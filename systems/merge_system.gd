extends Node

signal merge_success(result_id: String, level: int)
signal merge_failed(reason: String)
signal creature_unlocked(creature_id: String)
signal inventory_updated(inventory: Dictionary)

var balancing_config: Resource = preload("res://resources/balancing/game_balancing.tres")

var evolution_data: Dictionary = {}
var unlocked: Dictionary = {}

func _ready() -> void:
	load_evolution_data()

	# Load unlocked creatures from save
	refresh_unlocked()

func refresh_unlocked() -> void:
	unlocked = {}
	for creature_id in SaveSystem.get_unlocked_creatures():
		unlocked[creature_id] = true

# ── 1. INITIALIZATION (LOAD DATA) ─────────────────────────────────────

func load_evolution_data() -> void:
	var file := FileAccess.open("res://data/evolution_chains.json", FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			evolution_data = parsed

# ── 2. INVENTORY SYSTEM ───────────────────────────────────────────────

func add_creature(id: String, amount: int = 1) -> void:
	SaveSystem.add_to_inventory(id, amount)
	SaveSystem.save_game()
	emit_signal("inventory_updated", SaveSystem.get_inventory())

func remove_creature(id: String, amount: int = 1) -> bool:
	var success := SaveSystem.remove_from_inventory(id, amount)
	if success:
		SaveSystem.save_game()
		emit_signal("inventory_updated", SaveSystem.get_inventory())
	return success

# ── 3. CORE MERGE LOGIC ───────────────────────────────────────────────

func can_merge(id: String) -> bool:
	if get_next_evolution(id) == "":
		return false

	var required: int = get_merge_required(id)

	return SaveSystem.get_inventory_count(id) >= required

func merge(id: String) -> String:
	var next_id: String = get_next_evolution(id)
	if next_id == "":
		emit_signal("merge_failed", "No further evolution")
		return ""

	var required: int = get_merge_required(id)

	if SaveSystem.get_inventory_count(id) < required:
		emit_signal("merge_failed", "Not enough items")
		return ""

	# Remove items
	remove_creature(id, required)

	# Add next evolution
	add_creature(next_id, 1)

	# Store for overlay
	GameState.session_rewards = {
		"merged_creature": next_id
	}

	# Unlock tracking
	unlocked[next_id] = true
	SaveSystem.unlock_creature(next_id)
	SaveSystem.save_game()

	emit_signal("creature_unlocked", next_id)
	emit_signal("merge_success", next_id, get_evolution_level(next_id))

	if has_node("/root/TutorialSystem") and get_node("/root/TutorialSystem").is_active and get_node("/root/TutorialSystem").current_step == 5:
		get_node("/root/TutorialSystem").next_step()

	# UI feedback
	_emit_juice("merge_success", {"result_id": next_id, "level": get_evolution_level(next_id)})

	# Show success overlay
	var overlay_scene: PackedScene = load("res://scenes/overlays/merge_success_overlay.tscn")
	if overlay_scene:
		NavigationManager.push_overlay(overlay_scene)
	else:
		push_error("Failed to load merge_success_overlay.tscn")

	return next_id

func get_merge_required(creature_id: String) -> int:
	var base_required = 2
	var stage = get_evolution_level(creature_id)

	if balancing_config:
		base_required = balancing_config.get_merge_required(stage)
	elif evolution_data.has(creature_id):
		base_required = evolution_data[creature_id].get("required", 2)

	if has_node("/root/DebugTuner"):
		var debug_tuner = get_node("/root/DebugTuner")
		return debug_tuner.get_merge_cost(stage, base_required)

	if has_node("/root/RetentionSystem"):
		var day = get_node("/root/RetentionSystem").get_day_number()
		if day == 1 and creature_id == "egg":
			return 1

	return base_required

# ── 4. EVOLUTION LEVEL TRACKING ───────────────────────────────────────

func get_evolution_level(id: String) -> int:
	if has_node("/root/CreatureRegistry"):
		var data = get_node("/root/CreatureRegistry").get_creature(id)
		if data:
			return data.evolution_level

	var level: int = 0
	var current: String = id

	while evolution_data.has(current):
		level += 1
		var next_evolution: Variant = evolution_data[current]["next"]
		if next_evolution == null:
			break
		current = next_evolution as String

	return level

# ── 5. DRAG & DROP MERGE SUPPORT ───────────────────────────────────────

func validate_drag_merge(from_id: String, to_id: String) -> bool:
	if from_id != to_id:
		return false

	return can_merge(from_id)

func execute_drag_merge(id: String) -> String:
	return merge(id)

# ── 6. INVENTORY QUERY HELPERS ─────────────────────────────────────────

func get_inventory() -> Dictionary:
	return SaveSystem.get_inventory()

func has_creature(id: String) -> bool:
	return SaveSystem.get_inventory_count(id) > 0

func get_next_evolution(id: String) -> String:
	if evolution_data.has(id):
		return evolution_data[id]["next"]

	# Procedural Fallback (Task 17: Content Scaling)
	if has_node("/root/CreatureRegistry"):
		var registry = get_node("/root/CreatureRegistry")
		var data = registry.get_creature(id)
		if data:
			# Simple rule: same archetype, next tier
			var next_tier_id = (data.archetype + "_" + str(data.tier + 1)).to_lower()
			if registry.get_creature(next_tier_id):
				return next_tier_id

			# Branching rule: Slime Tier 3 evolves to Beast Tier 1
			if data.archetype == "Slime" and data.tier >= 3:
				return "beast_1"

	return ""

func get_all_creature_ids() -> Array[String]:
	var ids: Array[String] = []

	# Add base creatures from JSON
	for id in evolution_data.keys():
		if not ids.has(id):
			ids.append(id)

	# Add procedural creatures from registry (Task 17)
	if has_node("/root/CreatureRegistry"):
		for id in get_node("/root/CreatureRegistry").get_all_ids():
			if not ids.has(id):
				ids.append(id)

	return ids

func get_creature_name(creature_id: String) -> String:
	if has_node("/root/CreatureRegistry"):
		var data = get_node("/root/CreatureRegistry").get_creature(creature_id)
		if data:
			return data.name

	# For now, return capitalized ID as fallback
	# In future, this could load from creatures.json for display names
	return creature_id.capitalize()

# ── 7. UNLOCK SYSTEM ──────────────────────────────────────────────────

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

func get_unlocked_creatures() -> Array[String]:
	var result: Array[String] = []
	for creature_id in unlocked:
		if unlocked[creature_id]:
			result.append(creature_id)
	return result

# ── PRIVATE HELPERS ───────────────────────────────────────────────────

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)
