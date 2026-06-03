extends Resource
class_name EggType

# EggType Resource - Defines an egg type
# Per Data Model Section: ENTITY: EGG TYPE

@export var id: String = ""
@export var name: String = ""
@export var speciesId: String = ""
@export var price: int = 0
@export var eggSprite: String = ""  # Path to sprite, not Texture2D
