extends SubViewportContainer
class_name MonsterDisplay2

signal monster_tapped()

# --- Node References ---
@onready var _body_bone: Bone2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone
@onready var _head_bone: Bone2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone

@onready var _body_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySprite
@onready var _head_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/HeadSlotSprite
@onready var _face_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/FaceSlotSprite
@onready var _body_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySlotSprite

# --- Slot Data (Offsets are now relative to the Bone pivot) ---
const _SLOT_DATA: Dictionary = {
	"dino": {
		"adult": {
			"head": { "offset": Vector2(0, -10), "size": Vector2(128, 128) },
			"face": { "offset": Vector2(0, 20),  "size": Vector2(128, 96) },
			"body": { "offset": Vector2(0, 30),  "size": Vector2(256, 256) },
		}
	}
}

const SLOT_FILL := 0.90

var _sprite_cache: Dictionary = {}
var _current_species_id: String = "dino"
var _current_stage_name: String = "adult"
var _idle_tween: Tween = null
var _reaction_tween: Tween = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_play_tap_reaction()
		monster_tapped.emit()

# --- Public API ---
func set_monster(monster_data: Dictionary) -> void:
	_current_species_id = monster_data.get("speciesId", "dino")
	_current_stage_name = _get_stage_name(monster_data.get("stageId", "stage_3"))
	
	# Set base texture
	var path = _resolve_sprite_path(_current_species_id, monster_data.get("stageId", ""), monster_data.get("morphId", ""))
	_body_sprite.texture = _load_sprite(path)
	
	# Equip cosmetics
	equip_cosmetic("head", monster_data.get("equippedHeadId", ""))
	equip_cosmetic("face", monster_data.get("equippedFaceId", ""))
	equip_cosmetic("body", monster_data.get("equippedBodyId", ""))
	
	_start_idle_animation()

func equip_cosmetic(slot: String, cosmetic_id: String) -> void:
	var slot_sprite = _get_slot_sprite(slot)
	if not slot_sprite: return

	if cosmetic_id.is_empty():
		_clear_cosmetic_slot(slot)
		return

	var texture = _resolve_and_load_cosmetic(cosmetic_id, slot)
	if not texture: return

	var info = _get_slot_info(slot)
	var tex_size = Vector2(texture.get_width(), texture.get_height())
	var scale_factor = minf(info.size.x / tex_size.x, info.size.y / tex_size.y) * SLOT_FILL

	slot_sprite.texture = texture
	slot_sprite.position = info.offset # Relative to the bone!
	slot_sprite.scale = Vector2(scale_factor, scale_factor)
	slot_sprite.modulate = Color.WHITE

# --- Internals ---
func _get_slot_info(slot: String) -> Dictionary:
	var species = _SLOT_DATA.get(_current_species_id, _SLOT_DATA["dino"])
	return species.get(_current_stage_name, species["adult"]).get(slot)

func _get_slot_sprite(slot: String) -> Sprite2D:
	match slot:
		"head": return _head_slot_sprite
		"face": return _face_slot_sprite
		"body": return _body_slot_sprite
	return null

func _clear_cosmetic_slot(slot: String) -> void:
	var s = _get_slot_sprite(slot)
	if s: s.texture = null; s.modulate = Color.TRANSPARENT

func _load_sprite(path: String) -> Texture2D:
	if _sprite_cache.has(path): return _sprite_cache[path]
	var tex = load(path)
	if tex: _sprite_cache[path] = tex
	return tex

func _resolve_sprite_path(sid, stid, mid) -> String:
	return "res://assets/monsters/%s/%s_%s.png" % [sid, mid if mid else "default", _get_stage_name(stid)]

func _resolve_and_load_cosmetic(cid, slot) -> Texture2D:
	return _load_sprite("res://assets/cosmetics/%s/%s.png" % [slot, cid])

func _get_stage_name(id) -> String:
	match id:
		"stage_1": return "baby"
		"stage_2": return "kid"
		"stage_4": return "elder"
	return "adult"

# --- Skeletal Animations ---
func _start_idle_animation() -> void:
	if _idle_tween: _idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	
	# Breathe the whole body
	_idle_tween.tween_property(_body_bone, "scale", Vector2(1.05, 0.95), 1.2).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
	
	# Slight head bobbing (independent but inherits body scale)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -65.0, 0.6).set_trans(Tween.TRANS_SINE)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -60.0, 0.6).set_trans(Tween.TRANS_SINE)

func _play_tap_reaction() -> void:
	if _reaction_tween: _reaction_tween.kill()
	_reaction_tween = create_tween()
	_reaction_tween.tween_property(_body_bone, "scale", Vector2(1.2, 0.8), 0.1).set_trans(Tween.TRANS_ELASTIC)
	_reaction_tween.tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.2)
	_reaction_tween.finished.connect(_start_idle_animation)
