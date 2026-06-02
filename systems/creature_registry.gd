extends Node
## CreatureRegistry.gd
## Central repository for monster data and generation.

var ARCHETYPE_CONFIG = {
	"Egg": {
		"base_color": Color.ANTIQUE_WHITE,
		"symbol": "🥚",
		"stat_mod": 0.8,
		"rarity": 1.0
	},
	"Blob": {
		"base_color": Color.SKY_BLUE,
		"symbol": "🫧",
		"stat_mod": 1.0,
		"rarity": 0.9
	},
	"Slime": {
		"base_color": Color.LIME_GREEN,
		"symbol": "🐸",
		"stat_mod": 1.1,
		"rarity": 0.8
	},
	"Beast": {
		"base_color": Color.ORANGE_RED,
		"symbol": "🐺",
		"stat_mod": 1.3,
		"rarity": 0.6
	},
	"Dino": {
		"base_color": Color.DARK_SLATE_GRAY,
		"symbol": "🦖",
		"stat_mod": 1.5,
		"rarity": 0.4
	},
	"Dragon": {
		"base_color": Color.GOLD,
		"symbol": "🐉",
		"stat_mod": 2.0,
		"rarity": 0.2
	},
	"Cosmic": {
		"base_color": Color.MEDIUM_PURPLE,
		"symbol": "✨",
		"stat_mod": 3.0,
		"rarity": 0.05
	}
}

var registry = {} # id -> CreatureData

func _ready() -> void:
	_initialize_base_registry()
	_generate_procedural_content()

func _initialize_base_registry() -> void:
	# Keep the core chain as-is for the initial experience
	_add_to_registry("egg", "Mysterious Egg", "Egg", 1, 1, "🥚")
	_add_to_registry("baby_dino", "Baby Dino", "Blob", 1, 2, "🐣")
	_add_to_registry("raptor", "Swift Raptor", "Slime", 2, 3, "🦖")
	_add_to_registry("t_rex", "Ancient T-Rex", "Beast", 2, 4, "🦕")
	_add_to_registry("dragon", "Golden Dragon", "Dragon", 3, 5, "🐉")
	_add_to_registry("lava_dragon", "Lava Dragon", "Dragon", 4, 6, "🔥")
	# Shop skin creatures
	_add_to_registry("fire_dragon", "Fire Dragon", "Dragon", 4, 6, "🐉")
	_add_to_registry("frost_blob", "Frost Blob", "Blob", 1, 2, "🫧")
	_add_to_registry("zapling", "Zapling", "Slime", 2, 3, "⚡")
	_add_to_registry("gloom_spirit", "Gloom Spirit", "Cosmic", 3, 5, "👻")

func _generate_procedural_content() -> void:
	# Phase 1: Generate variants for existing archetypes
	# This demonstrates how we can scale to 100s of creatures easily
	var variants = ["Aqua", "Lava", "Ice", "Shadow", "Flora", "Electric"]

	for arch in ARCHETYPE_CONFIG.keys():
		if arch == "Egg": continue # Eggs are special

		for tier in range(1, 4): # Tiers 1-3
			for variant in variants:
				var variant_name = variant + " " + arch + " (T" + str(tier) + ")"
				var variant_id = (variant + "_" + arch + "_t" + str(tier)).to_lower()

				# Skip if already exists (e.g. hand-added core creatures)
				if registry.has(variant_id): continue

				_add_to_registry(variant_id, variant_name, arch, tier, tier * 2, ARCHETYPE_CONFIG[arch].symbol)

func _add_to_registry(id: String, monster_name: String, archetype: String, tier: int, evo: int, symbol: String) -> void:
	var data = CreatureData.new()
	data.id = id
	data.name = monster_name
	data.archetype = archetype
	data.tier = tier
	data.evolution_level = evo
	data.symbol = symbol

	# Apply archetype color if available
	if ARCHETYPE_CONFIG.has(archetype):
		data.visual_style["color"] = ARCHETYPE_CONFIG[archetype].base_color

	# Apply stat scaling formula
	var base_val = 10.0
	if ARCHETYPE_CONFIG.has(archetype):
		base_val *= ARCHETYPE_CONFIG[archetype].stat_mod

	data.base_power = int(scale_stat(base_val, tier, evo))

	registry[id] = data

func scale_stat(base: float, tier: int, evolution: int) -> float:
	return base * pow(1.25, tier) * pow(1.10, evolution)

func get_creature(id: String) -> CreatureData:
	return registry.get(id, null)

func get_all_ids() -> Array:
	return registry.keys()
