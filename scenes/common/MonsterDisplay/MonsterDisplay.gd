extends Control
class_name MonsterDisplay

# MonsterDisplay component - Renders monsters with equipped cosmetics
# Per UI Wireframe Section 14 and TDD Section 11

signal monster_tapped()

@onready var _sprite_root: Sprite2D = $SpriteRoot
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _cosmetic_layer: Node2D = $CosmeticLayer
@onready var _head_slot_sprite: Sprite2D = $CosmeticLayer/HeadSlotSprite
@onready var _face_slot_sprite: Sprite2D = $CosmeticLayer/FaceSlotSprite
@onready var _body_slot_sprite: Sprite2D = $CosmeticLayer/BodySlotSprite
@onready var _back_slot_sprite: Sprite2D = $CosmeticLayer/BackSlotSprite

# Sprite cache for performance optimization
var _sprite_cache: Dictionary = {}

var _current_monster_data: Dictionary = {}
var _current_species_id: String = ""
var _current_stage_id: String = ""
var _current_morph_id: String = ""

func _ready() -> void:
	print("[MonsterDisplay] _ready() called")
	_connect_signals()

func _connect_signals() -> void:
	print("[MonsterDisplay] Connecting gui_input")
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	print("[MonsterDisplay] _on_gui_input() called with event: ", event)
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		print("[MonsterDisplay] Emitting monster_tapped")
		monster_tapped.emit()

func set_monster(monster_data: Dictionary) -> void:
	_current_monster_data = monster_data
	
	if monster_data.has("speciesId"):
		_current_species_id = monster_data.speciesId
	if monster_data.has("stageId"):
		_current_stage_id = monster_data.stageId
	if monster_data.has("morphId"):
		_current_morph_id = monster_data.morphId
	
	update_sprite(_current_species_id, _current_stage_id, _current_morph_id)
	
	# Update cosmetics
	if monster_data.has("equippedHeadId"):
		equip_cosmetic("head", monster_data.equippedHeadId)
	if monster_data.has("equippedFaceId"):
		equip_cosmetic("face", monster_data.equippedFaceId)
	if monster_data.has("equippedBodyId"):
		equip_cosmetic("body", monster_data.equippedBodyId)
	if monster_data.has("equippedBackId"):
		equip_cosmetic("back", monster_data.equippedBackId)

func update_sprite(speciesId: String, stageId: String, morphId: String = "") -> void:
	_current_species_id = speciesId
	_current_stage_id = stageId
	_current_morph_id = morphId
	
	var sprite_path: String = _resolve_sprite_path(speciesId, stageId, morphId)
	var texture: Texture2D = _load_sprite(sprite_path)
	
	if texture:
		_sprite_root.texture = texture
		_sprite_root.modulate = Color.WHITE
	else:
		# Fallback to placeholder
		_sprite_root.texture = null
		push_warning("Monster sprite not found: %s" % sprite_path)

func _resolve_sprite_path(speciesId: String, stageId: String, morphId: String) -> String:
	# Base: {species}/{morph}_{stage}.png
	# Example: dino/default_adult.png or dino_fire_adult.png
	var morph_prefix: String = "default"
	if not morphId.is_empty():
		morph_prefix = morphId
	
	# Map stage IDs to stage names
	var stage_name: String = _get_stage_name(stageId)
	
	# First try the official path
	var primary_path: String = "res://assets/monsters/%s/%s_%s.png" % [speciesId, morph_prefix, stage_name]
	# If that doesn't exist, use the existing sprites in assets/sprites/
	return primary_path

func _get_stage_name(stageId: String) -> String:
	# Map stage IDs to stage names for sprite paths
	match stageId:
		"stage_0":
			return "egg"
		"stage_1":
			return "baby"
		"stage_2":
			return "kid"
		"stage_3":
			return "adult"
		"stage_4":
			return "elder"
		_:
			return "baby"  # Default fallback

func equip_cosmetic(slot: String, cosmeticId: String) -> void:
	if cosmeticId.is_empty():
		_clear_cosmetic_slot(slot)
		return
	
	var texture: Texture2D
	var cosmetic_resource_path: String = "res://data/cosmetics/%s.tres" % cosmeticId
	var cosmetic_resource: Resource = load(cosmetic_resource_path)
	if cosmetic_resource and cosmetic_resource is Cosmetic:
		texture = _load_sprite(cosmetic_resource.sprite_path)
	else:
		var cosmetic_path: String = _resolve_cosmetic_path(cosmeticId, slot)
		texture = _load_sprite(cosmetic_path)
	
	match slot:
		"head":
			_head_slot_sprite.texture = texture
			_head_slot_sprite.modulate = Color.WHITE if texture else Color.TRANSPARENT
		"face":
			_face_slot_sprite.texture = texture
			_face_slot_sprite.modulate = Color.WHITE if texture else Color.TRANSPARENT
		"body":
			_body_slot_sprite.texture = texture
			_body_slot_sprite.modulate = Color.WHITE if texture else Color.TRANSPARENT
		"back":
			_back_slot_sprite.texture = texture
			_back_slot_sprite.modulate = Color.WHITE if texture else Color.TRANSPARENT

func _clear_cosmetic_slot(slot: String) -> void:
	match slot:
		"head":
			_head_slot_sprite.texture = null
			_head_slot_sprite.modulate = Color.TRANSPARENT
		"face":
			_face_slot_sprite.texture = null
			_face_slot_sprite.modulate = Color.TRANSPARENT
		"body":
			_body_slot_sprite.texture = null
			_body_slot_sprite.modulate = Color.TRANSPARENT
		"back":
			_back_slot_sprite.texture = null
			_back_slot_sprite.modulate = Color.TRANSPARENT

func _resolve_cosmetic_path(cosmeticId: String, slot: String) -> String:
	# Cosmetic path: res://assets/cosmetics/{slot}/{cosmeticId}.png
	return "res://assets/cosmetics/%s/%s.png" % [slot, cosmeticId]

func _load_sprite(path: String) -> Texture2D:
	# Performance optimization: cache loaded sprites
	if _sprite_cache.has(path):
		return _sprite_cache[path]
	
	var texture: Texture2D = load(path)
	if texture:
		_sprite_cache[path] = texture
		return texture
	
	# Fallback to existing sprites if primary path fails
	var fallback_path: String = "res://assets/sprites/dino.png"
	texture = load(fallback_path)
	if texture:
		_sprite_cache[path] = texture
	
	return texture
