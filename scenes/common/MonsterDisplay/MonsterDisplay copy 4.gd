extends SubViewportContainer
class_name MonsterDisplay4

# MonsterDisplay component - Renders monsters using a modular 2D skeletal system.
# Cosmetics are nested directly under their associated bones, ensuring they
# organically scale, stretch, and bob alongside the pet's skeletal updates.
signal monster_tapped()

# --- Skeletal & Node References ---
@onready var _skeleton:         Skeleton2D      = $SubViewport/Monster2DScene/Skeleton2D
@onready var _body_bone:        Bone2D          = $SubViewport/Monster2DScene/Skeleton2D/BodyBone
@onready var _head_bone:        Bone2D          = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone

@onready var _body_sprite:      Sprite2D        = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySprite
@onready var _head_sprite:      Sprite2D        = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/HeadSprite

@onready var _head_slot_sprite: Sprite2D        = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/HeadSlotSprite
@onready var _face_slot_sprite: Sprite2D        = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/FaceSlotSprite
@onready var _body_slot_sprite: Sprite2D        = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySlotSprite

# --- IK Interactivity Nodes ---
@onready var _ik_target:        Marker2D        = $SubViewport/Monster2DScene/IKTarget

# ---------------------------------------------------------------------------
# SLOT DEFINITIONS
# offset  = position offset relative to the respective parent bone origin (px)
# size    = fixed cosmetic boundary size for rendering scale constraints (px)
# ---------------------------------------------------------------------------
const _SLOT_DATA: Dictionary = {
	"dino": {
		"adult": {
			"head": { "offset": Vector2(0,  -28), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,    8), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,   18), "size": Vector2(256, 256) },
		},
		"kid": {
			"head": { "offset": Vector2(0,  -22), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,   10), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,   12), "size": Vector2(256, 256) },
		},
		"baby": {
			"head": { "offset": Vector2(0,  -16), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,   12), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,    8), "size": Vector2(256, 256) },
		},
		"elder": {
			"head": { "offset": Vector2(0,  -30), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,    6), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,   20), "size": Vector2(256, 256) },
		},
	},
	"slime": {
		"adult": {
			"head": { "offset": Vector2(0,  -12), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,   20), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,   12), "size": Vector2(256, 256) },
		},
		"kid": {
			"head": { "offset": Vector2(0,   -8), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0,   22), "size": Vector2(128,  96) },
			"body": { "offset": Vector2(0,   10), "size": Vector2(256, 256) },
		},
	},
}

const SLOT_FILL := 0.90 

# --- Configuration & Engine Modifiers ---
@export var ik_follow_speed: float = 10.0
@export var is_ik_active: bool = true

# --- State Cache ---
var _sprite_cache: Dictionary = {} 
var _current_monster_data: Dictionary = {} 
var _current_species_id:   String = "" 
var _current_stage_id:     String = "" 
var _current_morph_id:     String = "" 
var _current_stage_name:   String = "" 

var _idle_tween:     Tween = null 
var _reaction_tween: Tween = null 

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------
func _ready() -> void:
	gui_input.connect(_on_gui_input) 
	
	# Turn on the structural IK modification execution stack if configured
	if _skeleton.get_modification_stack():
		_skeleton.get_modification_stack().enabled = is_ik_active

func _process(delta: float) -> void:
	if is_ik_active and has_node("SubViewport/Monster2DScene/IKTarget"):
		_update_ik_target_position(delta)

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.pressed): 
		_play_tap_reaction() 
		monster_tapped.emit() 

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

func set_monster(monster_data: Dictionary) -> void:
	_current_monster_data = monster_data

	if monster_data.has("speciesId"): _current_species_id = monster_data["speciesId"]
	if monster_data.has("morphId"):   _current_morph_id   = monster_data["morphId"]
	if monster_data.has("stageId"):
		_current_stage_id   = monster_data["stageId"]
		_current_stage_name = _get_stage_name(_current_stage_id)

	update_sprite(_current_species_id, _current_stage_id, _current_morph_id)

	equip_cosmetic("head", monster_data.get("equippedHeadId", ""))
	equip_cosmetic("face", monster_data.get("equippedFaceId", ""))
	equip_cosmetic("body", monster_data.get("equippedBodyId", ""))

	_start_idle_animation()

func update_sprite(species_id: String, stage_id: String, morph_id: String = "") -> void:
	_current_species_id = species_id
	_current_stage_id   = stage_id
	_current_stage_name = _get_stage_name(stage_id)
	_current_morph_id   = morph_id

	var path    := _resolve_sprite_path(species_id, stage_id, morph_id)
	var texture := _load_sprite(path)

	if texture:
		_body_sprite.texture  = texture
		_body_sprite.modulate = Color.WHITE
	else:
		_body_sprite.texture  = load("res://assets/sprites/dino.png")
		_body_sprite.modulate = Color.WHITE
		push_warning("[MonsterDisplay] Sprite missing, using placeholder: %s" % path)

func equip_cosmetic(slot: String, cosmetic_id: String) -> void:
	var slot_sprite := _get_slot_sprite(slot)
	if not slot_sprite:
		push_warning("[MonsterDisplay] Unknown slot: %s" % slot)
		return

	if cosmetic_id.is_empty():
		_clear_cosmetic_slot(slot)
		return

	var texture := _resolve_and_load_cosmetic(cosmetic_id, slot)
	if not texture:
		_clear_cosmetic_slot(slot)
		push_warning("[MonsterDisplay] Texture missing for cosmetic '%s' in slot '%s'" % [cosmetic_id, slot])
		return

	var info: Dictionary = _get_slot_info(slot)
	var offset: Vector2 = info.get("offset", Vector2.ZERO)
	var slot_size: Vector2 = info["size"]

	var tex_size: Vector2 = Vector2(texture.get_width(), texture.get_height())
	var scale_factor: float = minf(slot_size.x / tex_size.x, slot_size.y / tex_size.y) * SLOT_FILL

	slot_sprite.texture        = texture
	slot_sprite.region_enabled = false
	slot_sprite.scale          = Vector2(scale_factor, scale_factor)
	slot_sprite.position       = offset
	slot_sprite.modulate       = Color.WHITE

func set_ik_enabled(enabled: bool) -> void:
	is_ik_active = enabled
	var stack = _skeleton.get_modification_stack()
	if stack:
		stack.enabled = enabled

# ---------------------------------------------------------------------------
# INTERNALS
# ---------------------------------------------------------------------------

func _update_ik_target_position(delta: float) -> void:
	var local_mouse_pos = $SubViewport/Monster2DScene.get_local_mouse_position()
	
	# Smoothly interpolate the target position for organic momentum tracking
	_ik_target.global_position = _ik_target.global_position.lerp(
		$SubViewport/Monster2DScene.global_position + local_mouse_pos, 
		ik_follow_speed * delta
	)

func _clear_cosmetic_slot(slot: String) -> void:
	var slot_sprite := _get_slot_sprite(slot)
	if slot_sprite:
		slot_sprite.texture        = null
		slot_sprite.region_enabled = false
		slot_sprite.modulate       = Color.TRANSPARENT
		slot_sprite.position       = Vector2.ZERO
		slot_sprite.scale          = Vector2.ONE

func _get_slot_info(slot: String) -> Dictionary:
	var species: Dictionary = _SLOT_DATA.get(_current_species_id, _SLOT_DATA.get("dino", {}))
	var stage: Dictionary = species.get(_current_stage_name, species.get("adult", {}))
	return stage.get(slot, { "offset": Vector2.ZERO, "size": Vector2(128, 128) })

func _get_slot_sprite(slot: String) -> Sprite2D:
	match slot:
		"head": return _head_slot_sprite
		"face": return _face_slot_sprite
		"body": return _body_slot_sprite
		_:      return null

func _resolve_sprite_path(species_id: String, stage_id: String, morph_id: String) -> String:
	var morph  := "default" if morph_id.is_empty() else morph_id
	var stage  := _get_stage_name(stage_id)
	return "res://assets/monsters/%s/%s_%s.png" % [species_id, morph, stage]

func _resolve_and_load_cosmetic(cosmetic_id: String, slot: String) -> Texture2D:
	var res_path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var resource: Resource = load(res_path)
	if resource and resource is Cosmetic:
		return _load_sprite(resource.spritePath)
	return _load_sprite("res://assets/cosmetics/%s/%s.png" % [slot, cosmetic_id])

func _load_sprite(path: String) -> Texture2D:
	if _sprite_cache.has(path):
		return _sprite_cache[path]
	var texture: Texture2D = load(path)
	if texture:
		_sprite_cache[path] = texture
	return texture

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0": return "egg"
		"stage_1": return "baby"
		"stage_2": return "kid"
		"stage_3": return "adult"
		"stage_4": return "elder"
		_:         return "baby"

# ---------------------------------------------------------------------------
# SKELETAL TWEEENS (AXIE-STYLE)
# ---------------------------------------------------------------------------
func _start_idle_animation() -> void:
	if _idle_tween:
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops()

	# --- Torso Bone Breathing / Squash & Stretch ---
	_idle_tween.tween_property(_body_bone, "scale", Vector2(1.04, 0.96), 0.9) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_body_bone, "scale", Vector2(0.98, 1.02), 0.9) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# --- Head Bone Secondary Bobbing ---
	# Offset the timing from the main torso cycle to look fluid and jointed
	var bob := 4.0 if _current_species_id == "slime" else 2.5
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -60.0 - bob, 0.7) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -60.0 + bob, 0.7) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_tap_reaction() -> void:
	if _reaction_tween:
		_reaction_tween.kill()

	_reaction_tween = create_tween()
	_reaction_tween.set_parallel(true)

	# Sudden dynamic spring compression on the bones
	_reaction_tween.tween_property(_body_bone, "scale", Vector2(1.25, 0.75), 0.10) \
		.set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(_head_bone, "scale", Vector2(0.85, 1.20), 0.10) \
		.set_ease(Tween.EASE_OUT)
	
	# Elastic bounce back to default pose
	_reaction_tween.chain().set_parallel(true)
	_reaction_tween.tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_reaction_tween.tween_property(_head_bone, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_reaction_tween.chain().tween_callback(_start_idle_animation)
