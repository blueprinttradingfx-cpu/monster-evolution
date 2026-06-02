extends Node

signal data_updated()

var _save_data: Dictionary = {}

const SAVE_FILE_PATH := "user://save_v3.json"

func _ready() -> void:
	load_game()

func load_game() -> void:
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			_save_data = _migrate(parsed)
		else:
			push_warning("Corrupt save file, using default")
			_create_new_save()
	else:
		_create_new_save()

func _create_new_save() -> void:
	_save_data = {
		"version": 3,
		"meta": {
			"created_at": Time.get_unix_time_from_system(),
			"last_login": Time.get_unix_time_from_system()
		},
		"economy": {
			"coins": 0
		},
		"inventory": {},
		"progression": {
			"total_matches": 0,
			"boards_cleared": 0,
			"first_launch_date": 0,
			"total_login_days": 0,
			"last_login_date": "",
			"memory_level": 1
		},
		"unlocks": {
			"creatures": {
				"egg": true
			},
			"card_themes": {},
			"skins": {}
		},
		"settings": {
			"sound": true,
			"haptics": true,
			"sfx_volume": 1.0,
			"music_volume": 1.0
		},
		"daily": {
			"last_login_date": "",
			"streak": 0,
			"claimed": false
		}
	}
	save_game()

func _migrate(old_data: Dictionary) -> Dictionary:
	var version = old_data.get("version", 0)

	if version < 2:
		old_data = _migrate_v1_to_v2(old_data)
	
	if version < 3:
		old_data = _migrate_v2_to_v3(old_data)

	old_data["version"] = 3
	return old_data

func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	if not data.has("progression"):
		data["progression"] = {}
	if not data["progression"].has("memory_level"):
		data["progression"]["memory_level"] = 1
	return data

func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	# Update meta
	if not data.has("meta"):
		data["meta"] = {
			"created_at": Time.get_unix_time_from_system(),
			"last_login": Time.get_unix_time_from_system()
		}

	# Migrate inventory from array to dict
	if data.has("inventory") and data["inventory"] is Array:
		var old_inventory: Array = data["inventory"]
		var new_inventory: Dictionary = {}
		for item in old_inventory:
			if not new_inventory.has(item):
				new_inventory[item] = 0
			new_inventory[item] += 1
		data["inventory"] = new_inventory

	# Migrate unlocked_creatures from array to unlocks.creatures dict
	if data.has("unlocked_creatures") and data["unlocked_creatures"] is Array:
		if not data.has("unlocks"):
			data["unlocks"] = {"creatures": {}}
		for creature_id in data["unlocked_creatures"]:
			data["unlocks"]["creatures"][creature_id] = true

	return data

func save_game() -> void:
	_save_data["meta"]["last_login"] = Time.get_unix_time_from_system()

	var tmp_path := SAVE_FILE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_save_data))
		file.close()

		var abs_save_path := ProjectSettings.globalize_path(SAVE_FILE_PATH)
		var abs_tmp_path := ProjectSettings.globalize_path(tmp_path)
		var dir := DirAccess.open("user://")
		if dir:
			if FileAccess.file_exists(SAVE_FILE_PATH):
				dir.remove_absolute(abs_save_path)
			dir.rename_absolute(abs_tmp_path, abs_save_path)

		data_updated.emit()
	else:
		push_error("Failed to write save file")

func get_data() -> Dictionary:
	return _save_data.duplicate()

func add_coins(amount: int) -> void:
	_save_data["economy"]["coins"] += amount

func add_eggs(amount: int) -> void:
	add_inventory_item("egg", amount)

func add_inventory_item(creature_id: String, amount: int = 1) -> void:
	if not _save_data["inventory"].has(creature_id):
		_save_data["inventory"][creature_id] = 0
	_save_data["inventory"][creature_id] += amount

func add_to_inventory(creature_id: String, amount: int = 1) -> void:
	add_inventory_item(creature_id, amount)

func remove_from_inventory(creature_id: String, count: int = 1) -> bool:
	if not _save_data["inventory"].has(creature_id):
		return false
	if _save_data["inventory"][creature_id] < count:
		return false
	_save_data["inventory"][creature_id] -= count
	if _save_data["inventory"][creature_id] <= 0:
		_save_data["inventory"].erase(creature_id)
	return true

func get_inventory() -> Dictionary:
	return _save_data.get("inventory", {}).duplicate()

func get_inventory_count(creature_id: String) -> int:
	return _save_data["inventory"].get(creature_id, 0)

func get_unlocked_creatures() -> Array[String]:
	var arr: Array[String] = []
	if _save_data.has("unlocks") and _save_data["unlocks"].has("creatures"):
		for creature_id in _save_data["unlocks"]["creatures"]:
			if _save_data["unlocks"]["creatures"][creature_id]:
				arr.append(creature_id)
	return arr

func add_unlocked_creature(creature_id: String) -> void:
	unlock_creature(creature_id)

func unlock_creature(creature_id: String) -> void:
	if not _save_data.has("unlocks"):
		_save_data["unlocks"] = {"creatures": {}}
	if not _save_data["unlocks"].has("creatures"):
		_save_data["unlocks"]["creatures"] = {}
	_save_data["unlocks"]["creatures"][creature_id] = true

func unlock_card_theme(theme_id: String) -> void:
	if not _save_data.has("unlocks"):
		_save_data["unlocks"] = {"card_themes": {}, "skins": {}}
	if not _save_data["unlocks"].has("card_themes"):
		_save_data["unlocks"]["card_themes"] = {}
	_save_data["unlocks"]["card_themes"][theme_id] = true

func unlock_skin(skin_id: String) -> void:
	if not _save_data.has("unlocks"):
		_save_data["unlocks"] = {"card_themes": {}, "skins": {}}
	if not _save_data["unlocks"].has("skins"):
		_save_data["unlocks"]["skins"] = {}
	_save_data["unlocks"]["skins"][skin_id] = true

func is_card_theme_unlocked(theme_id: String) -> bool:
	return _save_data.get("unlocks", {}).get("card_themes", {}).get(theme_id, false)

func is_skin_unlocked(skin_id: String) -> bool:
	return _save_data.get("unlocks", {}).get("skins", {}).get(skin_id, false)

func get_unlocked_card_themes() -> Array[String]:
	var arr: Array[String] = []
	if _save_data.has("unlocks") and _save_data["unlocks"].has("card_themes"):
		for theme_id in _save_data["unlocks"]["card_themes"]:
			if _save_data["unlocks"]["card_themes"][theme_id]:
				arr.append(theme_id)
	return arr

func get_unlocked_skins() -> Array[String]:
	var arr: Array[String] = []
	if _save_data.has("unlocks") and _save_data["unlocks"].has("skins"):
		for skin_id in _save_data["unlocks"]["skins"]:
			if _save_data["unlocks"]["skins"][skin_id]:
				arr.append(skin_id)
	return arr

func add_rewards(rewards: Dictionary) -> void:
	add_coins(int(rewards.get("coins", 0)))
	var egg_count = int(rewards.get("eggs", 0))
	add_eggs(egg_count)
	save_game()

func get_setting(key: String) -> Variant:
	return _save_data.get("settings", {}).get(key, null)

func set_setting(key: String, value: Variant) -> void:
	_save_data["settings"][key] = value

func set_progression_value(key: String, value: Variant) -> void:
	if not _save_data.has("progression"):
		_save_data["progression"] = {}
	_save_data["progression"][key] = value

func increment_progression(matches: int = 0, boards: int = 0) -> void:
	_save_data["progression"]["total_matches"] += matches
	_save_data["progression"]["boards_cleared"] += boards

func check_daily_reward() -> bool:
	var date_dict: Dictionary = Time.get_date_dict_from_system()
	var today: String = "%d-%d-%d" % [date_dict.year, date_dict.month, date_dict.day]
	var saved_date: String = _save_data.get("daily", {}).get("last_login_date", "")

	if today == saved_date:
		if _save_data["daily"]["claimed"]:
			return false
		else:
			return true
	else:
		_save_data["daily"]["last_login_date"] = today
		if saved_date == "":
			_save_data["daily"]["streak"] = 1
		else:
			_save_data["daily"]["streak"] += 1
		_save_data["daily"]["claimed"] = false
		return true

func claim_daily_reward() -> void:
	_save_data["daily"]["claimed"] = true

	var reward_coins: int = 10 + (_save_data["daily"]["streak"] * 5)
	_save_data["economy"]["coins"] += reward_coins
	add_eggs(1)
	save_game()

func reset_save() -> void:
	_create_new_save()
