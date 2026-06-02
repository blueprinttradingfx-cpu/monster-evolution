extends Resource
class_name CreatureData
## CreatureData.gd
## Base resource for all monsters.

@export var id: String = ""
@export var name: String = ""
@export var archetype: String = "" # Egg, Blob, Slime, Beast, Dino, Dragon, Cosmic
@export var tier: int = 1
@export var evolution_level: int = 1
@export var symbol: String = "❓"

@export_group("Stats")
@export var base_coins_per_match: int = 10
@export var base_power: int = 10

@export_group("Visuals")
@export var visual_style: Dictionary = {
	"shape": "blob",
	"color": Color.WHITE,
	"scale": 1.0
}
