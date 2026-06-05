extends Node

# SaveManager autoload - JSON-based save/load with validation and atomic writes
# Per Event Flow Section 3.4, Data Model, and AGENTS.md Section 2

# --- CONSTANTS ---
const SAVE_PATH: String = "user://save_data.json"
const SAVE_TEMP_PATH: String = "user://save_data.json.tmp"
const CURRENT_VERSION: int = 1

# --- VARIABLES ---
var save_data: Dictionary = {}

# --- INITIALIZATION ---
func _ready() -> void:
	load_game()

# --- SAVE FUNCTIONS ---
func save_game() -> void:
	# Gather data from all managers
	save_data = _gather_save_data()
	
	# Validate data before writing
	if not _validate_save_data(save_data):
		push_error("Save failed: Data validation failed")
		return
	
	# Convert to JSON
	var json_string: String = JSON.stringify(save_data, "\t")
	
	# Atomic write pattern per AGENTS.md Section 2.3:
	# Write to temp file first, then rename to avoid mid-write corruption
	var temp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if not temp_file:
		push_error("Save failed: Could not open temp file")
		return
	
	temp_file.store_string(json_string)
	temp_file.close()
	
	# Rename temp file to actual save file (atomic operation)
	var dir: DirAccess = DirAccess.open("user://")
	if not dir:
		push_error("Save failed: Could not access user directory")
		return
	
	if dir.rename(SAVE_TEMP_PATH, SAVE_PATH) != OK:
		push_error("Save failed: Could not rename temp file")
		return
	
	print("Game saved successfully")

func _gather_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": CURRENT_VERSION,
		"player": {
			"coins": EconomyManager.get_coins() if EconomyManager else 0,
			"activeMonsterId": GameManager.activeMonsterId if GameManager else "",
			"ownedMonsterIds": MonsterManager.get_owned_monster_ids() if MonsterManager else [],
			"ownedCosmeticIds": MonsterManager.owned_cosmetic_ids if MonsterManager else [],
			"ownedEggIds": MonsterManager.owned_egg_ids if MonsterManager else [],
			"totalEggsHatched": GameManager.totalEggsHatched if GameManager else 0,
			"totalCoinsEarned": GameManager.totalCoinsEarned if GameManager else 0,
			"totalMiniGamesPlayed": GameManager.totalMiniGamesPlayed if GameManager else 0,
			"createdAt": GameManager.createdAt if GameManager else ""
		},
		"monsters": MonsterManager.get_all_monsters() if MonsterManager else [],
		"ownedEggs": MonsterManager.get_owned_eggs() if MonsterManager else [],
		"ownedCosmetics": [],  # TODO: Implement cosmetic inventory
		"transactions": EconomyManager.transactions if EconomyManager else []  # Optional debug entity per Data Model
	}
	return data

# --- LOAD FUNCTIONS ---
func load_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if not file:
		print("No save file found, starting new game")
		_initialize_new_save()
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	# Sanitize JSON input per AGENTS.md Section 2.4
	var json_parser: JSON = JSON.new()
	var parse_result: int = json_parser.parse(json_string)
	
	if parse_result != OK or typeof(json_parser.data) != TYPE_DICTIONARY:
		push_error("Save file corrupt, starting new game")
		_initialize_new_save()
		return
	
	var loaded_data: Dictionary = json_parser.data
	
	# Validate loaded data per AGENTS.md Section 2.1: Never trust save file data
	if not _validate_save_data(loaded_data):
		push_error("Save file invalid, starting new game")
		_initialize_new_save()
		return
	
	# Migrate if needed
	if loaded_data.get("version", 0) < CURRENT_VERSION:
		loaded_data = _migrate_save_data(loaded_data)
	
	save_data = loaded_data
	_distribute_save_data()
	print("Game loaded successfully")

func _validate_save_data(data: Dictionary) -> bool:
	# Basic validation per AGENTS.md Section 2.1
	if not data.has("version"):
		data["version"] = CURRENT_VERSION
	
	if not data.has("player"):
		data["player"] = {}
	
	if not data.player.has("coins"):
		data.player["coins"] = 1000
	
	if typeof(data.player.coins) != TYPE_INT:
		data.player["coins"] = 1000
	
	# Add any missing top-level keys
	if not data.has("monsters"):
		data["monsters"] = []
	if not data.has("ownedEggs"):
		data["ownedEggs"] = []
	if not data.has("ownedCosmetics"):
		data["ownedCosmetics"] = []
	if not data.has("transactions"):
		data["transactions"] = []
	
	# Add any missing player keys
	if not data.player.has("activeMonsterId"):
		data.player["activeMonsterId"] = ""
	if not data.player.has("ownedMonsterIds"):
		data.player["ownedMonsterIds"] = []
	if not data.player.has("ownedCosmeticIds"):
		data.player["ownedCosmeticIds"] = []
	if not data.player.has("ownedEggIds"):
		data.player["ownedEggIds"] = []
	if not data.player.has("totalEggsHatched"):
		data.player["totalEggsHatched"] = 0
	if not data.player.has("totalCoinsEarned"):
		data.player["totalCoinsEarned"] = 0
	if not data.player.has("totalMiniGamesPlayed"):
		data.player["totalMiniGamesPlayed"] = 0
	if not data.player.has("createdAt"):
		data.player["createdAt"] = ""
	
	return true

func _migrate_save_data(data: Dictionary) -> Dictionary:
	# Handle save data migration between versions
	var version: int = data.get("version", 0)
	
	# Migration from version 0 to 1
	if version < 1:
		# Add missing fields with defaults
		if not data.has("transactions"):
			data["transactions"] = []
		
		if not data.has("ownedEggs"):
			data["ownedEggs"] = []
		
		if not data.has("ownedCosmetics"):
			data["ownedCosmetics"] = []
	
	data["version"] = CURRENT_VERSION
	print("Migrated save data from version %d to %d" % [version, CURRENT_VERSION])
	return data

func _distribute_save_data() -> void:
	# Distribute loaded data to managers
	if EconomyManager and save_data.has("player"):
		EconomyManager.set_coins(save_data.player.get("coins", 0))
	
	if EconomyManager and save_data.has("transactions"):
		EconomyManager.transactions = save_data.transactions
	
	if GameManager and save_data.has("player"):
		GameManager.activeMonsterId = save_data.player.get("activeMonsterId", "")
		GameManager.totalEggsHatched = save_data.player.get("totalEggsHatched", 0)
		GameManager.totalCoinsEarned = save_data.player.get("totalCoinsEarned", 0)
		GameManager.totalMiniGamesPlayed = save_data.player.get("totalMiniGamesPlayed", 0)
		GameManager.createdAt = save_data.player.get("createdAt", "")
	
	if MonsterManager and save_data.has("monsters"):
		MonsterManager.load_monsters(save_data.monsters)
	
	if MonsterManager and save_data.has("ownedEggs"):
		MonsterManager.load_eggs(save_data.ownedEggs)
	
	if MonsterManager and save_data.has("player"):
		MonsterManager.load_cosmetics(save_data.player.get("ownedCosmeticIds", []))

func _initialize_new_save() -> void:
	# Create starter egg
	var starter_egg_id: String = "egg_%d" % Time.get_unix_time_from_system()
	var starter_egg: Dictionary = {
		"id": starter_egg_id,
		"eggTypeId": "dino_egg",
		"acquiredAt": _get_current_timestamp()
	}
	
	# Get starting coins from balancing config if available
	var starting_coins: int = 1000
	if EconomyManager and EconomyManager.balancing_config:
		starting_coins = EconomyManager.balancing_config.starting_coins
	
	save_data = {
		"version": CURRENT_VERSION,
		"player": {
			"coins": starting_coins,
			"activeMonsterId": "",
			"ownedMonsterIds": [],
			"ownedCosmeticIds": [],
			"ownedEggIds": [starter_egg_id],
			"totalEggsHatched": 0,
			"totalCoinsEarned": 0,
			"totalMiniGamesPlayed": 0,
			"createdAt": _get_current_timestamp()
		},
		"monsters": [],
		"ownedEggs": [starter_egg],
		"ownedCosmetics": [],
		"transactions": []
	}
	
	_distribute_save_data()
	save_game()

func _get_current_timestamp() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

# --- RESET FUNCTIONS ---
func reset_game() -> void:
	_initialize_new_save()
	save_game()
	print("Game reset to initial state")

# --- AUTO-SAVE TRIGGERS ---
# Called by managers on critical actions per Event Flow Section 12
# UI should never call this directly - UI emits signals, managers handle logic and save

func trigger_save_on_purchase() -> void:
	save_game()

func trigger_save_on_hatch() -> void:
	save_game()

func trigger_save_on_evolution() -> void:
	save_game()

func trigger_save_on_equip_change() -> void:
	save_game()
