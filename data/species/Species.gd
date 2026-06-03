extends Resource
class_name Species

# Species Resource - Defines a monster family
# Per Data Model Section: ENTITY: SPECIES

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var eggTypeId: String = ""
@export var availableMorphIds: Array[String] = []
@export var evolutionStageIds: Array[String] = []
