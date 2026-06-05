extends SubViewportContainer
class_name MonsterDisplayx

# MonsterDisplay component - Renders monsters with equipped cosmetics
# Per UI Wireframe Section 14 and TDD Section 11

signal monster_tapped()

@onready var _sprite_root: Sprite2D = $SubViewport/Monster2DScene/SpriteRoot
@onready var _animation_player: AnimationPlayer = $SubViewport/Monster2DScene/AnimationPlayer
@onready var _back_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/SpriteRoot/BackSlotSprite
@onready var _body_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/SpriteRoot/BodySlotSprite
@onready var _face_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/SpriteRoot/FaceSlotSprite
@onready var _head_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/SpriteRoot/HeadSlotSprite

# Sprite cache for performance optimization
var _sprite_cache: Dictionary = {}

# Cosmetic positioning offsets per species/stage (slot -> Vector2 offset)
const _COSMETIC_OFFSETS: Dictionary = {
	"dino": {
		"adult": {
			"head": Vector2(0, -76),
			"face": Vector2(0, -40),
			"body": Vector2(0, 30),
			"back": Vector2(-10, 20),
		},
		"kid": {
			"head": Vector2(0, -66),
			"face": Vector2(0, -24),
			"body": Vector2(0, 24),
			"back": Vector2(-10, 12),
		},
		"baby": {
			"head": Vector2(0, -80),
			"face": Vector2(0, -48),
			"body": Vector2(0, 10),
			"back": Vector2(-10, 2),
		},
	},
	"slime": {
		"adult": {
			"head": Vector2(0, -60),
			"face": Vector2(0, -24),
			"body": Vector2(0, 24),
			"back": Vector2(-10, 20),
		},
		"kid": {
			"head": Vector2(0, -66),
			"face": Vector2(0, -24),
			"body": Vector2(0, 26),
			"back": Vector2(-10, 14),
		},
	},
}

# Cosmetic scale adjustments per species/stage (slot -> float scale)
const _COSMETIC_SCALES: Dictionary = {
	"dino": {
		"adult": {
			"head": 1.0,
			"face": 1.0,
			"body": 1.0,
			"back": 1.0,
		},
		"kid": {
			"head": 1.0,
			"face": 1.0,
			"body": 1.0,
			"back": 1.0,
		},
		"baby": {
			"head": 1.0,
			"face": 1.0,
			"body": 1.0,
			"back": 1.0,
		},
	},
	"slime": {
		"adult": {
			"head": 1.0,
			"face": 1.0,
			"body": 1.0,
			"back": 1.0,
		},
		"kid": {
			"head": 1.0,
			"face": 1.0,
			"body": 1.0,
			"back": 1.0,
		},
	},
}

var _current_monster_data: Dictionary = {}
var _current_species_id: String = ""
var _current_stage_id: String = ""
var _current_morph_id: String = ""
var _current_stage_name: String = ""

# Animation tweens
var _idle_tween: Tween = null
var _reaction_tween: Tween = null

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
		_play_tap_reaction()
		monster_tapped.emit()

func set_monster(monster_data: Dictionary) -> void:
	_current_monster_data = monster_data
	
	if monster_data.has("speciesId"):
		_current_species_id = monster_data.speciesId
	if monster_data.has("stageId"):
		_current_stage_id = monster_data.stageId
		_current_stage_name = _get_stage_name(_current_stage_id)
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
	
	# Start idle animation
	_start_idle_animation()

func update_sprite(speciesId: String, stageId: String, morphId: String = "") -> void:
	_current_species_id = speciesId
	_current_stage_id = stageId
	_current_stage_name = _get_stage_name(stageId)
	_current_morph_id = morphId
	
	var sprite_path: String = _resolve_sprite_path(speciesId, stageId, morphId)
	var texture: Texture2D = _load_sprite(sprite_path)
	
	if texture:
		_sprite_root.texture = texture
		_sprite_root.modulate = Color.WHITE
	else:
		# Explicit fallback — load directly, don't cache under wrong key
		_sprite_root.texture = load("res://assets/sprites/dino.png")
		_sprite_root.modulate = Color.WHITE
		push_warning("[MonsterDisplay] Using placeholder for: %s" % sprite_path)

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
	
	var texture: Texture2D = _resolve_and_load_cosmetic(cosmeticId, slot)
	
	var slot_sprite: Sprite2D = _get_slot_sprite(slot)
	if slot_sprite:
		slot_sprite.texture = texture
		
		# Set position and scale based on species and stage
		var offset: Vector2 = _get_slot_offset(slot)
		var scale: float = _get_slot_scale(slot)
		slot_sprite.position = offset
		slot_sprite.scale = Vector2(scale, scale)
	
	# modulate — show if texture loaded, hide if not
	if slot_sprite:
		slot_sprite.modulate = Color.WHITE if texture else Color.TRANSPARENT

func _clear_cosmetic_slot(slot: String) -> void:
	var slot_sprite: Sprite2D = _get_slot_sprite(slot)
	if slot_sprite:
		slot_sprite.texture = null
		slot_sprite.modulate = Color.TRANSPARENT
		slot_sprite.position = Vector2.ZERO
		slot_sprite.scale = Vector2.ONE

func _resolve_and_load_cosmetic(cosmeticId: String, slot: String) -> Texture2D:
	var cosmetic_resource_path: String = "res://data/cosmetics/%s.tres" % cosmeticId
	var cosmetic_resource: Resource = load(cosmetic_resource_path)
	if cosmetic_resource and cosmetic_resource is Cosmetic:
		return _load_sprite(cosmetic_resource.spritePath)
	else:
		var cosmetic_path: String = _resolve_cosmetic_path(cosmeticId, slot)
		return _load_sprite(cosmetic_path)

func _resolve_cosmetic_path(cosmeticId: String, slot: String) -> String:
	# Cosmetic path: res://assets/cosmetics/{slot}/{cosmeticId}.png
	return "res://assets/cosmetics/%s/%s.png" % [slot, cosmeticId]

func _get_slot_sprite(slot: String) -> Sprite2D:
	match slot:
		"head": return _head_slot_sprite
		"face": return _face_slot_sprite
		"body": return _body_slot_sprite
		"back": return _back_slot_sprite
		_: return null

func _get_slot_offset(slot: String) -> Vector2:
	# Default to (0,0) if not found
	var species_data: Dictionary = _COSMETIC_OFFSETS.get(_current_species_id, {})
	var stage_data: Dictionary = species_data.get(_current_stage_name, {})
	return stage_data.get(slot, Vector2.ZERO)

func _get_slot_scale(slot: String) -> float:
	# Default to 1.0 if not found
	var species_data: Dictionary = _COSMETIC_SCALES.get(_current_species_id, {})
	var stage_data: Dictionary = species_data.get(_current_stage_name, {})
	return stage_data.get(slot, 1.0)

func _load_sprite(path: String) -> Texture2D:
	if _sprite_cache.has(path):
		return _sprite_cache[path]
	
	var texture: Texture2D = load(path)
	if texture:
		_sprite_cache[path] = texture
		return texture
	
	push_warning("[MonsterDisplay] Sprite not found: %s" % path)
	return null

# --- IDLE ANIMATIONS ---
func _start_idle_animation() -> void:
	if _idle_tween:
		_idle_tween.kill()
	
	_idle_tween = create_tween().set_loops()
	
	# Breathing animation (subtle scale)
	_idle_tween.tween_property(_sprite_root, "scale", Vector2(1.05, 1.05), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_sprite_root, "scale", Vector2(1.0, 1.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Bobbing animation (vertical movement) - species-specific
	var bob_amount: float = 5.0 if _current_species_id == "slime" else 3.0
	var bob_speed: float = 1.5 if _current_species_id == "slime" else 2.0
	_idle_tween.tween_property(_sprite_root, "position:y", -bob_amount, bob_speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_sprite_root, "position:y", bob_amount, bob_speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Slime squish effect (asymmetric scale)
	if _current_species_id == "slime":
		_idle_tween.tween_property(_sprite_root, "scale:x", 1.1, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_idle_tween.tween_property(_sprite_root, "scale:x", 0.95, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_tap_reaction() -> void:
	if _reaction_tween:
		_reaction_tween.kill()
	
	_reaction_tween = create_tween()
	_reaction_tween.set_parallel(true)
	
	# Quick bounce/scale reaction
	_reaction_tween.tween_property(_sprite_root, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_reaction_tween.tween_property(_sprite_root, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
	
	# Return to idle after reaction
	_reaction_tween.tween_callback(_start_idle_animation)
