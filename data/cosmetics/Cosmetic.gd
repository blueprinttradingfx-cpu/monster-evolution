extends Resource
class_name Cosmetic

# Cosmetic Resource - Defines a cosmetic item
# Per Data Model Section: ENTITY: COSMETIC

@export var id: String = ""
@export var name: String = ""
@export var slot: String = ""  # head/face/body/back
@export var speciesId: String = ""
@export var price: int = 0
@export var spritePath: String = ""
