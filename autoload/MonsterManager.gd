extends Node

# MonsterManager autoload - Monster lifecycle and collection management
# Per Event Flow Section 3.3 and Data Model

# --- SIGNALS ---
signal monster_hatched(monsterId: String)
signal monster_evolved(monsterId: String)
signal monster_updated(monsterId: String)
signal egg_hatched(monsterId: String)  # New signal for egg hatching
signal egg_count_changed()  # New signal for egg count changes
signal morph_changed(monsterId: String, morphId: String)
signal egg_purchased(eggTypeId: String)
signal cosmetic_purchased(cosmeticId: String)
signal cosmetic_equipped(monster_id: String, slot: String, cosmetic_id: String)

# --- VARIABLES ---
var monsters: Dictionary = {}  # monsterId -> Monster data
var owned_eggs: Dictionary = {}  # ownedEggId -> OwnedEgg data
var owned_egg_ids: Array = []  # List of owned egg IDs for iteration
var owned_cosmetic_ids: Array = []  # List of owned cosmetic IDs
var evolution_config: EvolutionConfig

# --- CONSTANTS ---
const MAX_STAGE: int = 4  # Elder stage

# --- INITIALIZATION ---
func _ready() -> void:
	_load_evolution_config()
	print("MonsterManager initialized")

func _load_evolution_config() -> void:
	var config_path: String = "res://data/evolution/evolution_config.tres"
	var loaded_config: Resource = load(config_path)
	if loaded_config and loaded_config is EvolutionConfig:
		evolution_config = loaded_config
		print("Loaded evolution config successfully")
	else:
		push_error("Failed to load evolution config from %s" % config_path)

# --- MONSTER CREATION ---
func create_monster(speciesId: String, eggTypeId: String) -> String:
	# Generate unique monster ID
	var monsterId: String = _generate_monster_id()
	
	# Create monster at stage 1 (baby)
	var monster_data: Dictionary = {
		"id": monsterId,
		"speciesId": speciesId,
		"stageId": "stage_1",
		"morphId": "",
		"equippedHeadId": "",
		"equippedFaceId": "",
		"equippedBodyId": "",
		"equippedBackId": "",
		"createdAt": _get_current_timestamp(),
		"hatchedAt": _get_current_timestamp()
	}
	
	monsters[monsterId] = monster_data
	
	# Add to player's ownedMonsterIds (this will be handled by SaveManager)
	
	# Increment analytics
	if GameManager:
		GameManager.increment_eggs_hatched()
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()
	
	monster_hatched.emit(monsterId)
	
	print("Created monster: %s (species: %s, stage: %s)" % [monsterId, speciesId, "stage_1"])
	return monsterId

func _generate_monster_id() -> String:
	return "monster_%d" % Time.get_unix_time_from_system()

func _get_current_timestamp() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

# --- MONSTER EVOLUTION ---
func evolve_monster(monsterId: String) -> bool:
	if not monsters.has(monsterId):
		push_error("Evolution failed: Monster %s not found" % monsterId)
		return false
	
	var monster_data: Dictionary = monsters[monsterId]
	var current_stage_id: String = monster_data.get("stageId", "stage_0")
	
	# Check if evolution is possible (not at elder stage)
	if current_stage_id == "stage_%d" % MAX_STAGE:
		push_warning("Evolution failed: Monster already at max stage")
		return false
	
	# Get evolution cost
	var cost: int = get_evolution_cost(monsterId)
	if cost == 0:
		push_warning("Evolution failed: Monster already at max stage")
		return false
	
	# Check if player has enough coins
	if not EconomyManager:
		push_error("Evolution failed: EconomyManager not available")
		return false
	
	if not EconomyManager.can_afford(cost):
		push_warning("Evolution failed: Insufficient coins (need %d)" % cost)
		return false
	
	# Deduct coins
	if not EconomyManager.spend_coins(cost):
		push_error("Evolution failed: Coin deduction failed")
		return false
	
	# Advance to next stage
	var next_stage_id: String = _get_next_stage_id(current_stage_id)
	monster_data["stageId"] = next_stage_id
	monster_data["evolvedAt"] = _get_current_timestamp()
	
	monsters[monsterId] = monster_data
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()
	
	monster_evolved.emit(monsterId)
	
	print("Evolved monster %s to stage %s" % [monsterId, next_stage_id])
	return true

func get_evolution_cost(monsterId: String) -> int:
	if not monsters.has(monsterId):
		push_error("get_evolution_cost: Monster %s not found" % monsterId)
		return 0
	
	var monster_data: Dictionary = monsters[monsterId]
	var current_stage_id: String = monster_data.get("stageId", "stage_0")
	var stage_number: int = _get_stage_number(current_stage_id)
	
	# Return 0 if already at max stage
	if stage_number >= MAX_STAGE:
		return 0
	
	# Use evolution config to get cost
	if evolution_config:
		return evolution_config.get_evolution_cost(current_stage_id)
	
	# Fallback to hardcoded values if config fails to load
	match stage_number:
		0: return 0
		1: return 100
		2: return 500
		3: return 1500
		_: return 0

func _get_next_stage_id(current_stage_id: String) -> String:
	var stage_number: int = _get_stage_number(current_stage_id)
	var next_stage: int = min(stage_number + 1, MAX_STAGE)
	return "stage_%d" % next_stage

func _get_stage_number(stage_id: String) -> int:
	match stage_id:
		"stage_0": return 0
		"stage_1": return 1
		"stage_2": return 2
		"stage_3": return 3
		"stage_4": return 4
		_: return 0

# --- ACTIVE MONSTER MANAGEMENT ---
func set_active_monster(monsterId: String) -> void:
	if not monsters.has(monsterId):
		push_warning("set_active_monster: Monster %s not found" % monsterId)
		return
	
	if GameManager:
		GameManager.set_active_monster(monsterId)
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()

# --- COSMETIC EQUIPPING ---

# --- COLLECTION MANAGEMENT ---
func get_monster(monsterId: String) -> Dictionary:
	if monsters.has(monsterId):
		return monsters[monsterId]
	return {}

func get_all_monsters() -> Array:
	return monsters.values()

func get_owned_monster_ids() -> Array:
	return monsters.keys()

func get_active_monster() -> Dictionary:
	if not GameManager or GameManager.activeMonsterId.is_empty():
		return {}
	return get_monster(GameManager.activeMonsterId)

func load_monsters(monster_list: Array) -> void:
	monsters.clear()
	for monster_data in monster_list:
		if monster_data.has("id"):
			monsters[monster_data.id] = monster_data
	print("Loaded %d monsters" % monsters.size())

# --- EGG MANAGEMENT ---
func add_egg(egg_id_or_type: String, egg_type_id: String = "") -> String:
	# Handle both cases: add_egg(egg_type) or add_egg(egg_id, egg_type)
	var egg_id: String
	var final_egg_type: String
	
	if egg_type_id.is_empty():
		# Just egg type provided, generate id
		egg_id = "egg_%d" % Time.get_unix_time_from_system()
		final_egg_type = egg_id_or_type
	else:
		# Both id and type provided
		egg_id = egg_id_or_type
		final_egg_type = egg_type_id
	
	# Create OwnedEgg entry
	var egg_data: Dictionary = {
		"id": egg_id,
		"eggTypeId": final_egg_type,
		"acquiredAt": _get_current_timestamp()
	}
	
	owned_eggs[egg_id] = egg_data
	owned_egg_ids.append(egg_id)
	
	# Emit signal that egg count changed
	egg_count_changed.emit()
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()
	
	print("Added egg: %s (type: %s)" % [egg_id, final_egg_type])
	return egg_id

func get_owned_egg_count() -> int:
	return owned_egg_ids.size()

func load_cosmetics(cosmetic_ids: Array) -> void:
	owned_cosmetic_ids = cosmetic_ids.duplicate()
	print("Loaded %d owned cosmetics" % owned_cosmetic_ids.size())

func get_owned_eggs() -> Array:
	# Return all owned eggs as an array of dictionaries
	var eggs: Array = []
	for egg_id in owned_egg_ids:
		if owned_eggs.has(egg_id):
			eggs.append(owned_eggs[egg_id])
	return eggs

func hatch_egg(owned_egg_id: String) -> String:
	# Validate egg exists
	if not owned_eggs.has(owned_egg_id):
		push_error("Hatch failed: Egg %s not found" % owned_egg_id)
		return ""
	
	# Get egg data
	var egg_data: Dictionary = owned_eggs[owned_egg_id]
	var egg_type_id: String = egg_data.get("eggTypeId", "")
	
	# Get species ID from egg type
	var species_id: String = _get_species_id_from_egg(egg_type_id)
	
	# Remove egg from inventory
	owned_eggs.erase(owned_egg_id)
	var index: int = owned_egg_ids.find(owned_egg_id)
	if index != -1:
		owned_egg_ids.remove_at(index)
	
	# Emit signal that egg count changed
	egg_count_changed.emit()
	
	# Create monster
	var monster_id: String = create_monster(species_id, egg_type_id)
	
	# Emit egg hatched signal
	egg_hatched.emit(monster_id)
	
	print("Hatched egg: %s → monster: %s" % [owned_egg_id, monster_id])
	return monster_id

func _get_species_id_from_egg(egg_type_id: String) -> String:
	# Map egg types to species
	match egg_type_id:
		"dino_egg":
			return "dino"
		"slime_egg":
			return "slime"
		_:
			return "dino"

func load_eggs(egg_list: Array) -> void:
	owned_eggs.clear()
	owned_egg_ids.clear()
	for egg_data in egg_list:
		if egg_data.has("id"):
			owned_eggs[egg_data.id] = egg_data
			owned_egg_ids.append(egg_data.id)
	print("Loaded %d eggs" % owned_eggs.size())

func set_morph(monsterId: String, morphId: String) -> void:
	if not monsters.has(monsterId):
		push_error("set_morph: Monster %s not found" % monsterId)
		return
	
	var monster_data: Dictionary = monsters[monsterId]
	var species_id: String = monster_data.get("speciesId", "")
	var current_stage_id: String = monster_data.get("stageId", "stage_1")
	var current_stage_num: int = _get_stage_number(current_stage_id)
	
	# Get available morphs for this species
	var available_morphs: Array = get_available_morphs(species_id, current_stage_num)
	var is_valid_morph: bool = false
	
	if morphId.is_empty():
		is_valid_morph = true
	else:
		for morph in available_morphs:
			if morph.get("id", "") == morphId:
				is_valid_morph = true
				break
	
	if not is_valid_morph:
		push_warning("set_morph: Morph %s not available for species %s at stage %d" % [morphId, species_id, current_stage_num])
		return
	
	monster_data["morphId"] = morphId
	monsters[monsterId] = monster_data
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()
	
	morph_changed.emit(monsterId, morphId)
	print("Set morph %s for monster %s" % [morphId, monsterId])

func buy_egg(eggTypeId: String) -> bool:
	# Load egg type to get price
	var egg_type_path: String = "res://data/eggs/%s.tres" % eggTypeId
	var egg_type: Resource = load(egg_type_path)
	
	if not egg_type or not egg_type is EggType:
		push_error("buy_egg: Egg type %s not found" % eggTypeId)
		return false
	
	# Check economy manager
	if not EconomyManager:
		push_error("buy_egg: EconomyManager not available")
		return false
	
	# Check sufficient coins
	if not EconomyManager.can_afford(egg_type.price):
		push_warning("buy_egg: Insufficient coins for %s (need %d)" % [eggTypeId, egg_type.price])
		return false
	
	# Spend coins
	if not EconomyManager.spend_coins(egg_type.price, "egg_purchase_%s" % eggTypeId):
		push_error("buy_egg: Failed to spend coins")
		return false
	
	# Add egg to inventory
	add_egg(eggTypeId)
	
	# Emit signal
	egg_purchased.emit(eggTypeId)
	
	if OS.is_debug_build():
		print("[MonsterManager] Purchased egg: %s for %d coins" % [eggTypeId, egg_type.price])
	
	return true

func buy_cosmetic(cosmeticId: String) -> bool:
	# Load cosmetic
	var cosmetic_path: String = "res://data/cosmetics/%s.tres" % cosmeticId
	var cosmetic: Resource = load(cosmetic_path)
	
	if not cosmetic or not cosmetic is Cosmetic:
		push_error("buy_cosmetic: Cosmetic %s not found" % cosmeticId)
		return false
	
	# Check if already owned
	if owned_cosmetic_ids.has(cosmeticId):
		push_warning("buy_cosmetic: Cosmetic %s already owned" % cosmeticId)
		return false
	
	# Check economy manager
	if not EconomyManager:
		push_error("buy_cosmetic: EconomyManager not available")
		return false
	
	# Check sufficient coins
	if not EconomyManager.can_afford(cosmetic.price):
		push_warning("buy_cosmetic: Insufficient coins for %s (need %d)" % [cosmeticId, cosmetic.price])
		return false
	
	# Spend coins
	if not EconomyManager.spend_coins(cosmetic.price, "cosmetic_purchase_%s" % cosmeticId):
		push_error("buy_cosmetic: Failed to spend coins")
		return false
	
	# Add to owned cosmetics
	owned_cosmetic_ids.append(cosmeticId)
	
	# Emit signal
	cosmetic_purchased.emit(cosmeticId)
	
	# Trigger save
	if SaveManager:
		SaveManager.save_game()
	
	if OS.is_debug_build():
		print("[MonsterManager] Purchased cosmetic: %s for %d coins" % [cosmeticId, cosmetic.price])
	
	return true

func get_equipped_cosmetic(monster_id: String, slot: String) -> String:
	if not monsters.has(monster_id):
		push_error("get_equipped_cosmetic: Monster %s not found" % monster_id)
		return ""
	
	var monster_data: Dictionary = monsters[monster_id]
	var key := "equipped%sId" % slot.capitalize()
	return monster_data.get(key, "")

func equip_cosmetic(monster_id: String, slot: String, cosmetic_id: String) -> bool:
	if not monsters.has(monster_id):
		push_error("equip_cosmetic: Monster %s not found" % monster_id)
		return false
	
	if not owned_cosmetic_ids.has(cosmetic_id):
		push_warning("equip_cosmetic: Cosmetic %s not owned" % cosmetic_id)
		return false
	
	var cosmetic_path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var cosmetic_resource: Resource = load(cosmetic_path)
	if not cosmetic_resource or not cosmetic_resource is Cosmetic:
		push_error("equip_cosmetic: Cosmetic %s invalid" % cosmetic_id)
		return false
	
	if cosmetic_resource.slot != slot:
		push_warning("equip_cosmetic: Cosmetic %s is for slot %s, not %s" % [cosmetic_id, cosmetic_resource.slot, slot])
		return false
	
	var monster_data: Dictionary = monsters[monster_id]
	if cosmetic_resource.speciesId != monster_data.get("speciesId", ""):
		push_warning("equip_cosmetic: Cosmetic %s is for species %s, not %s" % [cosmetic_id, cosmetic_resource.speciesId, monster_data.get("speciesId", "")])
		return false
	
	var key := "equipped%sId" % slot.capitalize()
	monster_data[key] = cosmetic_id
	
	if SaveManager:
		SaveManager.save_game()
	
	cosmetic_equipped.emit(monster_id, slot, cosmetic_id)
	monster_updated.emit(monster_id)
	
	if OS.is_debug_build():
		print("[MonsterManager] Equipped %s on %s in slot %s" % [cosmetic_id, monster_id, slot])
	
	return true

func unequip_cosmetic(monster_id: String, slot: String) -> void:
	if not monsters.has(monster_id):
		push_error("unequip_cosmetic: Monster %s not found" % monster_id)
		return
	
	var monster_data: Dictionary = monsters[monster_id]
	var key := "equipped%sId" % slot.capitalize()
	monster_data[key] = ""
	
	if SaveManager:
		SaveManager.save_game()
	
	cosmetic_equipped.emit(monster_id, slot, "")
	monster_updated.emit(monster_id)
	
	if OS.is_debug_build():
		print("[MonsterManager] Unequipped %s from slot %s" % [monster_id, slot])

func get_owned_cosmetics_for_slot(species_id: String, slot: String) -> Array:
	var cosmetics: Array = []
	for cosmetic_id in owned_cosmetic_ids:
		var path := "res://data/cosmetics/%s.tres" % cosmetic_id
		var res: Resource = load(path)
		if res and res is Cosmetic and res.slot == slot and res.speciesId == species_id:
			cosmetics.append(cosmetic_id)
	return cosmetics

func get_available_morphs(speciesId: String, stageNum: int) -> Array:
	# Get all morph resources for the species
	var morphs: Array = []
	
	# Hard-coded morph data for now (can be replaced with resource loading later)
	if speciesId == "dino":
		morphs = [
			{"id": "fire", "name": "Fire Dino", "description": "A fiery dino!", "unlockStage": 3},
			{"id": "ice", "name": "Ice Dino", "description": "An icy dino!", "unlockStage": 3},
			{"id": "rock", "name": "Rock Dino", "description": "A rocky dino!", "unlockStage": 3}
		]
	elif speciesId == "slime":
		morphs = [
			{"id": "poison", "name": "Poison Slime", "description": "A poisonous slime!", "unlockStage": 3},
			{"id": "crystal", "name": "Crystal Slime", "description": "A crystalline slime!", "unlockStage": 3},
			{"id": "electric", "name": "Electric Slime", "description": "An electric slime!", "unlockStage": 3}
		]
	
	# Filter morphs unlocked at current stage
	var unlocked_morphs: Array = []
	for morph in morphs:
		if morph.get("unlockStage", 0) <= stageNum:
			unlocked_morphs.append(morph)
	
	return unlocked_morphs


