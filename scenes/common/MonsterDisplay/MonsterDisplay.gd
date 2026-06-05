extends SubViewportContainer
class_name MonsterDisplay

# MonsterDisplay component - Renders monsters with equipped cosmetics
# Slots: head (helmet 128x128), face (eyes 128x96), body (clothes/armor 256x256)
# Cosmetic assets are fixed-canvas — no crop math needed, just scale-to-fit.

signal monster_tapped()

@onready var _sprite_root:      Sprite2D      = $SubViewport/Monster2DScene/SpriteRoot
@onready var _animation_player: AnimationPlayer = $SubViewport/Monster2DScene/AnimationPlayer
@onready var _head_slot_sprite: Sprite2D      = $SubViewport/Monster2DScene/SpriteRoot/CosmeticsRoot/HeadSlotSprite
@onready var _face_slot_sprite: Sprite2D      = $SubViewport/Monster2DScene/SpriteRoot/CosmeticsRoot/FaceSlotSprite
@onready var _body_slot_sprite: Sprite2D      = $SubViewport/Monster2DScene/SpriteRoot/CosmeticsRoot/BodySlotSprite

# ---------------------------------------------------------------------------
# SLOT DEFINITIONS
# center  = where the slot anchor sits in viewport/canvas space (px)
# size    = the fixed cosmetic canvas size for that slot (px)
#           head  → 128x128  (square,   helmets / tall hats)
#           face  → 128x96   (landscape, eyes / masks)
#           body  → 256x256  (square,   armour / clothes)
# All cosmetic PNGs must be generated at exactly these dimensions.
# ---------------------------------------------------------------------------
const _SLOT_DATA: Dictionary = {
	"dino": {
		"adult": {
			"head": { "center": Vector2(128,  52), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128,  88), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 158), "size": Vector2(256, 256) },
		},
		"kid": {
			"head": { "center": Vector2(128,  58), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128,  90), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 152), "size": Vector2(256, 256) },
		},
		"baby": {
			"head": { "center": Vector2(128,  64), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128,  92), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 148), "size": Vector2(256, 256) },
		},
		"elder": {
			"head": { "center": Vector2(128,  50), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128,  86), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 160), "size": Vector2(256, 256) },
		},
	},
	"slime": {
		"adult": {
			"head": { "center": Vector2(128,  68), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128, 100), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 152), "size": Vector2(256, 256) },
		},
		"kid": {
			"head": { "center": Vector2(128,  72), "size": Vector2(128, 128) },
			"face": { "center": Vector2(128, 102), "size": Vector2(128,  96) },
			"body": { "center": Vector2(128, 150), "size": Vector2(256, 256) },
		},
	},
}

# Cosmetic fills this fraction of its slot box (keeps a small margin).
# Raise toward 1.0 for tighter fit, lower for more breathing room.
const SLOT_FILL := 0.90

# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------
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

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.pressed):
		_play_tap_reaction()
		monster_tapped.emit()

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Call this to fully set up a monster: sprite + all equipped cosmetics + animation.
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

## Swap the base pet sprite without touching cosmetics.
func update_sprite(species_id: String, stage_id: String, morph_id: String = "") -> void:
	_current_species_id = species_id
	_current_stage_id   = stage_id
	_current_stage_name = _get_stage_name(stage_id)
	_current_morph_id   = morph_id

	var path    := _resolve_sprite_path(species_id, stage_id, morph_id)
	var texture := _load_sprite(path)

	if texture:
		_sprite_root.texture  = texture
		_sprite_root.modulate = Color.WHITE
	else:
		_sprite_root.texture  = load("res://assets/sprites/dino.png")
		_sprite_root.modulate = Color.WHITE
		push_warning("[MonsterDisplay] Sprite missing, using placeholder: %s" % path)

## Equip or clear a single cosmetic slot at runtime (e.g. wardrobe preview).
## Pass an empty string to unequip.
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
	var slot_center: Vector2 = info["center"]
	var slot_size: Vector2 = info["size"]

	# Fixed-canvas assets: scale the whole texture to fit SLOT_FILL of the slot box.
	# Aspect ratio is always preserved — the asset canvas defines the ratio.
	var tex_size: Vector2 = Vector2(texture.get_width(), texture.get_height())
	var scale_factor: float = minf(slot_size.x / tex_size.x, slot_size.y / tex_size.y) * SLOT_FILL

	# Slot centers are in viewport space; SpriteRoot sits at (128,128),
	# so cosmetic positions must be relative to SpriteRoot.
	var local_pos: Vector2 = slot_center - _sprite_root.position

	slot_sprite.texture        = texture
	slot_sprite.region_enabled = false          # no cropping — canvas is already exact
	slot_sprite.scale          = Vector2(scale_factor, scale_factor)
	slot_sprite.position       = local_pos
	slot_sprite.modulate       = Color.WHITE

# ---------------------------------------------------------------------------
# INTERNALS — cosmetics
# ---------------------------------------------------------------------------

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
	return stage.get(slot, { "center": Vector2(128, 128), "size": Vector2(128, 128) })

func _get_slot_sprite(slot: String) -> Sprite2D:
	match slot:
		"head": return _head_slot_sprite
		"face": return _face_slot_sprite
		"body": return _body_slot_sprite
		_:      return null

# ---------------------------------------------------------------------------
# INTERNALS — asset loading
# ---------------------------------------------------------------------------

func _resolve_sprite_path(species_id: String, stage_id: String, morph_id: String) -> String:
	var morph  := "default" if morph_id.is_empty() else morph_id
	var stage  := _get_stage_name(stage_id)
	return "res://assets/monsters/%s/%s_%s.png" % [species_id, morph, stage]

func _resolve_and_load_cosmetic(cosmetic_id: String, slot: String) -> Texture2D:
	# Primary: .tres resource file with a Cosmetic class (spritePath property)
	var res_path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var resource: Resource = load(res_path)
	if resource and resource is Cosmetic:
		return _load_sprite(resource.spritePath)
	# Fallback: direct PNG at assets/cosmetics/{slot}/{id}.png
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
# ANIMATIONS
# SpriteRoot is tweened (breathing, bobbing, squish, tap reaction).
# CosmeticsRoot is a child of SpriteRoot but cosmetics are positioned in
# local space — they follow the pet naturally without being independently
# tweened, so they never distort.
# ---------------------------------------------------------------------------

func _start_idle_animation() -> void:
	if _idle_tween:
		_idle_tween.kill()

	# Store the rest position so bobbing always returns to the same origin.
	var rest_y := _sprite_root.position.y

	_idle_tween = create_tween().set_loops()

	# Breathing — subtle uniform scale pulse
	_idle_tween.tween_property(_sprite_root, "scale", Vector2(1.05, 1.05), 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_sprite_root, "scale", Vector2(1.0, 1.0), 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Bobbing — species-specific speed and range
	var bob    := 5.0 if _current_species_id == "slime" else 3.0
	var speed  := 1.5 if _current_species_id == "slime" else 2.0
	_idle_tween.tween_property(_sprite_root, "position:y", rest_y - bob, speed) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_sprite_root, "position:y", rest_y + bob, speed) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Slime-only horizontal squish
	if _current_species_id == "slime":
		_idle_tween.tween_property(_sprite_root, "scale:x", 1.1,  1.5) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_idle_tween.tween_property(_sprite_root, "scale:x", 0.95, 1.5) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_tap_reaction() -> void:
	if _reaction_tween:
		_reaction_tween.kill()

	_reaction_tween = create_tween()
	_reaction_tween.set_parallel(true)

	# Quick bounce then settle — overshoot on the way out, ease on the way back
	_reaction_tween.tween_property(_sprite_root, "scale", Vector2(1.2, 1.2), 0.10) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_reaction_tween.tween_property(_sprite_root, "scale", Vector2(1.0, 1.0), 0.20) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Resume idle once reaction finishes
	_reaction_tween.chain().tween_callback(_start_idle_animation)
