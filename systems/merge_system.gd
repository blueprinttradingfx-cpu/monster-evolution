extends Node

signal merge_succeeded(result_id: String, level: int)
signal merge_failed(reason: String)
signal creature_unlocked(creature_id: String)
signal inventory_updated(inventory: Dictionary)

var _creatures_data: Dictionary = {}
var _unlocked: Dictionary = {}

func _ready() -> void:
	var file := FileAccess.open("res://data/creatures.json", FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			_creatures_data = parsed
	
	# Load unlocked creatures from save
	for creature_id in SaveSystem.get_unlocked_creatures():
		_unlocked[creature_id] = true

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

func can_merge(creature_id_a: String, creature_id_b: String) -> bool:
	if creature_id_a != creature_id_b:
		return false
	if not _creatures_data.has(creature_id_a):
		return false
	if SaveSystem.get_inventory_count(creature_id_a) < 2:
		return false
	return _creatures_data[creature_id_a]["next"] != null

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)

func merge(creature_id_a: String, creature_id_b: String) -> String:
	if not can_merge(creature_id_a, creature_id_b):
		merge_failed.emit("Cannot merge these creatures")
		return ""
	
	var result_id: String = _creatures_data[creature_id_a]["next"]
	
	remove_creature(creature_id_a, 2)
	add_creature(result_id, 1)
	
	GameState.session_rewards = {
		"merged_creature": result_id
	}
	
	var level := get_evolution_level(result_id)
	merge_succeeded.emit(result_id, level)
	_emit_juice("merge_success", {"result_id": result_id, "level": level})
	
	if not _unlocked.has(result_id):
		_unlocked[result_id] = true
		SaveSystem.add_unlocked_creature(result_id)
		SaveSystem.save_game()
		emit_signal("creature_unlocked", result_id)
	
	var overlay_scene: PackedScene = load("res://scenes/overlays/merge_success_overlay.tscn")
	NavigationManager.push_overlay(overlay_scene)
	
	return result_id

func get_next_evolution(creature_id: String) -> String:
	if not _creatures_data.has(creature_id):
		return ""
	return _creatures_data[creature_id].get("next", "")

func is_terminal(creature_id: String) -> bool:
	if not _creatures_data.has(creature_id):
		return true
	return _creatures_data[creature_id]["next"] == null

func get_all_creature_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _creatures_data.keys():
		ids.append(id)
	return ids

func get_creature_name(creature_id: String) -> String:
	if not _creatures_data.has(creature_id):
		return "Unknown"
	return _creatures_data[creature_id]["name"]

func get_evolution_level(id: String) -> int:
	if not _creatures_data.has(id):
		return 0
	return int(_creatures_data[id].get("tier", 0))

func has_creature(id: String) -> bool:
	return SaveSystem.get_inventory_count(id) > 0

func get_inventory() -> Dictionary:
	return SaveSystem.get_inventory()

func is_unlocked(id: String) -> bool:
	return _unlocked.get(id, false)

func validate_drag_merge(from_id: String, to_id: String) -> bool:
	if from_id != to_id:
		return false
	return can_merge(from_id, to_id)

func execute_drag_merge(id: String) -> String:
	return merge(id, id)
