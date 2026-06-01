extends Node

signal merge_success(result_id: String, level: int)
signal merge_failed(reason: String)
signal creature_unlocked(creature_id: String)
signal inventory_updated(inventory: Dictionary)

var evolution_data: Dictionary = {}
var unlocked: Dictionary = {}

func _ready() -> void:
	load_evolution_data()

	# Load unlocked creatures from save
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
	if not evolution_data.has(id):
		return false

	var required: int = evolution_data[id]["required"]

	return SaveSystem.get_inventory_count(id) >= required

func merge(id: String) -> String:
	if not evolution_data.has(id):
		emit_signal("merge_failed", "Invalid creature")
		return ""

	var data: Dictionary = evolution_data[id]
	var required: int = data["required"]
	var next_id: String = data["next"]

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

	# UI feedback
	_emit_juice("merge_success", {"result_id": next_id, "level": get_evolution_level(next_id)})

	# Show success overlay
	var overlay_scene: PackedScene = load("res://scenes/overlays/merge_success_overlay.tscn")
	if overlay_scene:
		NavigationManager.push_overlay(overlay_scene)
	else:
		push_error("Failed to load merge_success_overlay.tscn")

	return next_id

# ── 4. EVOLUTION LEVEL TRACKING ───────────────────────────────────────

func get_evolution_level(id: String) -> int:
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

	return ""

func get_all_creature_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in evolution_data.keys():
		ids.append(id)
	return ids

func get_creature_name(creature_id: String) -> String:
	# For now, return capitalized ID as fallback
	# In future, this could load from creatures.json for display names
	return creature_id.capitalize()

# ── 7. UNLOCK SYSTEM ──────────────────────────────────────────────────

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

# ── PRIVATE HELPERS ───────────────────────────────────────────────────

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)
