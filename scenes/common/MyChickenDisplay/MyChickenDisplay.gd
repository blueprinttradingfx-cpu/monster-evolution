extends SubViewportContainer
class_name MyChickenDisplay

# MyChickenDisplay - Interactive chicken puppet, based on PetDisplay architecture
# Drives breathing loops, action triggers, expressions, and click-and-drag physics.

signal monster_tapped()
signal monster_drag_started()
signal monster_drag_ended()

# --- Core Skeleton Links ---
@onready var _skeleton: Skeleton2D = $SubViewport/Monster2DScene/Skeleton2D
@onready var _body_bone: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/Body
@onready var _head_bone: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/Body/Head

# --- Bone Joint Links (For Procedural Rotations) ---
@onready var _left_wing_bone: Bone2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/left_wingBone2D
@onready var _right_wing_bone: Bone2D = $SubViewport/Monster2DScene/Skeleton2D/Body/right_wingBone2D
@onready var _left_foot_bone: Bone2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/left_footBone2D
@onready var _right_foot_bone: Bone2D = $SubViewport/Monster2DScene/Skeleton2D/Body/right_footBone2D

# --- Sprite Links ---
@onready var _front_wing: Sprite2D   = $SubViewport/Monster2DScene/Skeleton2D/Body/left_wingBone2D/left_wing
@onready var _rear_wing: Sprite2D    = $SubViewport/Monster2DScene/Skeleton2D/Body/right_wingBone2D/right_wing
@onready var _front_foot: Sprite2D   = $SubViewport/Monster2DScene/Skeleton2D/Body/left_footBone2D/left_foot
@onready var _rear_foot: Sprite2D    = $SubViewport/Monster2DScene/Skeleton2D/Body/right_footBone2D/right_foot

# --- Feature Layer Slots (Facial Expressions) ---
@onready var _body_sprite: Sprite2D       = $SubViewport/Monster2DScene/Skeleton2D/Body/body
@onready var _head_sprite: Sprite2D       = $SubViewport/Monster2DScene/Skeleton2D/Body/Head/head
@onready var _eyes_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/Head/Face/face
@onready var _mouth_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/Body/Head/Face/face

# --- Cosmetic Slot Links ---
@onready var _head_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/Head/Hair/hair
@onready var _face_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/Head/Face/face
@onready var _body_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/Body/body

# --- Interactive Drag & Physics State Settings ---
@export var follow_speed: float = 12.0
@export var drag_elasticity: float = 15.0

var _is_dragging: bool = false
var _drag_velocity: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _base_body_rest_pos: Vector2 = Vector2(256, 300)

var _idle_tween: Tween = null
var _action_tween: Tween = null
var _next_flavor_action_timer: float = 4.0

# ---------------------------------------------------------------------------
# INITIALIZATION & INPUT MANAGER
# ---------------------------------------------------------------------------
func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_base_body_rest_pos = _body_bone.position
	_start_breathing_loop()

func _process(delta: float) -> void:
	if _is_dragging:
		_process_drag_physics(delta)
	else:
		_process_ambient_timers(delta)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_last_mouse_pos = get_global_mouse_position()
			if _idle_tween: _idle_tween.kill()
			if _action_tween: _action_tween.kill()
			monster_tapped.emit()
			monster_drag_started.emit()
			_set_expression("surprised")
		else:
			if _is_dragging:
				_is_dragging = false
				monster_drag_ended.emit()
				_play_drop_impact()

# ---------------------------------------------------------------------------
# EXPRESSION CONTROLLER (DYNAMIC FACE TEXTURING)
# ---------------------------------------------------------------------------
func _set_expression(state: String) -> void:
	match state:
		"happy":
			_eyes_slot_sprite.texture = load("res://assets/sprites/chicken/smile.png")
		"sad", "sigh":
			_eyes_slot_sprite.texture = load("res://assets/sprites/chicken/eyes_closed.png")
		"surprised", "dragged":
			_eyes_slot_sprite.texture = load("res://assets/sprites/chicken/laugh.png")
		_: # Neutral baseline
			_eyes_slot_sprite.texture = load("res://assets/sprites/chicken/face.png")

# ---------------------------------------------------------------------------
# INTERACTIVE DRAG PHYSICS
# ---------------------------------------------------------------------------
func _process_drag_physics(delta: float) -> void:
	var current_mouse := get_global_mouse_position()
	var frame_movement := current_mouse - _last_mouse_pos
	_last_mouse_pos = current_mouse

	var scene_node := $SubViewport/Monster2DScene as Node2D
	if scene_node:
		var target_bone_offset: Vector2 = scene_node.get_local_mouse_position()
		_body_bone.position = _body_bone.position.lerp(target_bone_offset, follow_speed * delta)

	# Inertial sway logic
	_drag_velocity = _drag_velocity.lerp(frame_movement / delta, 10.0 * delta)
	var travel_lean := clampf(_drag_velocity.x * -0.002, -0.4, 0.4)
	var vertical_drop := clampf(_drag_velocity.y * 0.002, -0.6, 0.6)
	
	_body_bone.rotation = lerpf(_body_bone.rotation, travel_lean, 8.0 * delta)
	_head_bone.rotation = lerpf(_head_bone.rotation, -travel_lean * 0.5, 8.0 * delta)
	
	# Rotate the bone containers rather than the sprites directly for structural stability
	_left_wing_bone.rotation = lerpf(_left_wing_bone.rotation, -vertical_drop - (travel_lean * 0.5), 10.0 * delta)
	_right_wing_bone.rotation = lerpf(_right_wing_bone.rotation, vertical_drop - (travel_lean * 0.5), 10.0 * delta)
	
	# Feet hang straight down with subtle aerodynamic drag
	_left_foot_bone.rotation = lerpf(_left_foot_bone.rotation, -travel_lean * 0.3, 8.0 * delta)
	_right_foot_bone.rotation = lerpf(_right_foot_bone.rotation, -travel_lean * 0.3, 8.0 * delta)

func _play_drop_impact() -> void:
	if _action_tween: _action_tween.kill()
	_action_tween = create_tween()
	
	# Ground impact bounce and squash compression phase
	_action_tween.tween_property(_body_bone, "position", _base_body_rest_pos, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.2, 0.8), 0.15)
	_action_tween.parallel().tween_property(_body_bone, "rotation", 0.0, 0.15)
	
	# Reset bone joint angles cleanly
	_action_tween.parallel().tween_property(_left_wing_bone, "rotation", 0.0, 0.15)
	_action_tween.parallel().tween_property(_right_wing_bone, "rotation", 0.0, 0.15)
	_action_tween.parallel().tween_property(_left_foot_bone, "rotation", 0.0, 0.15)
	_action_tween.parallel().tween_property(_right_foot_bone, "rotation", 0.0, 0.15)
	
	# Elastic rebound back to rest state
	_action_tween.chain().tween_property(_body_bone, "scale", Vector2(0.97, 1.03), 0.12)
	_action_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.08)
	_action_tween.chain().tween_callback(func(): 
		_set_expression("neutral")
		_start_breathing_loop()
	)

# ---------------------------------------------------------------------------
# AMBIENT ENGINE & ACTIONS (BREATHING, WAVING, SIGHING, JUMPING)
# ---------------------------------------------------------------------------
func _start_breathing_loop() -> void:
	if _idle_tween: _idle_tween.kill()
	_idle_tween = create_tween().set_loops()

	# Continuous breathing loop squash and stretch deforms
	_idle_tween.tween_property(_body_bone, "scale", Vector2(1.02, 0.97), 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -117.5, 1.1)
	
	_idle_tween.tween_property(_body_bone, "scale", Vector2(0.99, 1.01), 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -122.5, 1.1)

func _process_ambient_timers(delta: float) -> void:
	_next_flavor_action_timer -= delta
	if _next_flavor_action_timer <= 0.0:
		_next_flavor_action_timer = randf_range(4.5, 8.0)
		_trigger_random_flavor_action()

func _trigger_random_flavor_action() -> void:
	if _is_dragging: return
	var roll := randi() % 3
	match roll:
		0: _action_wave()
		1: _action_sigh()
		2: _action_jump()

func _action_wave() -> void:
	if _idle_tween: _idle_tween.pause()
	_set_expression("happy")
	
	var wave_tween := create_tween()
	wave_tween.tween_property(_left_wing_bone, "rotation", -0.8, 0.15).set_trans(Tween.TRANS_SINE)
	wave_tween.chain().tween_property(_left_wing_bone, "rotation", -0.2, 0.15).set_trans(Tween.TRANS_SINE)
	wave_tween.chain().tween_property(_left_wing_bone, "rotation", -0.8, 0.15).set_trans(Tween.TRANS_SINE)
	wave_tween.chain().tween_property(_left_wing_bone, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	wave_tween.tween_callback(func():
		_set_expression("neutral")
		if _idle_tween: _idle_tween.play()
	)

func _action_sigh() -> void:
	if _idle_tween: _idle_tween.pause()
	_set_expression("sigh")
	
	var sigh_tween := create_tween()
	sigh_tween.tween_property(_body_bone, "scale", Vector2(0.96, 0.94), 0.6).set_trans(Tween.TRANS_SINE)
	sigh_tween.parallel().tween_property(_head_bone, "position:y", -114.0, 0.6)
	sigh_tween.parallel().tween_property(_left_wing_bone, "rotation", 0.15, 0.6)
	sigh_tween.parallel().tween_property(_right_wing_bone, "rotation", -0.15, 0.6)
	
	sigh_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.5)
	sigh_tween.parallel().tween_property(_head_bone, "position:y", -120.0, 0.5)
	sigh_tween.parallel().tween_property(_left_wing_bone, "rotation", 0.0, 0.5)
	sigh_tween.parallel().tween_property(_right_wing_bone, "rotation", 0.0, 0.5)
	
	sigh_tween.tween_callback(func():
		_set_expression("neutral")
		if _idle_tween: _idle_tween.play()
	)

func _action_jump() -> void:
	if _idle_tween: _idle_tween.pause()
	
	var jump_tween := create_tween()
	# Crouch
	jump_tween.tween_property(_body_bone, "position:y", _base_body_rest_pos.y + 15.0, 0.12).set_trans(Tween.TRANS_QUAD)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.12, 0.88), 0.12)
	
	# Airborne launch phase
	jump_tween.chain().tween_property(_body_bone, "position:y", _base_body_rest_pos.y - 60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(0.9, 1.1), 0.22)
	jump_tween.parallel().tween_property(_left_wing_bone, "rotation", -0.4, 0.2)
	jump_tween.parallel().tween_property(_right_wing_bone, "rotation", 0.4, 0.2)
	
	# Falling and floor landing rebound
	jump_tween.chain().tween_property(_body_bone, "position:y", _base_body_rest_pos.y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.15, 0.85), 0.18)
	jump_tween.parallel().tween_property(_left_wing_bone, "rotation", 0.0, 0.15)
	jump_tween.parallel().tween_property(_right_wing_bone, "rotation", 0.0, 0.15)
	
	jump_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.12)
	jump_tween.tween_callback(func():
		if _idle_tween: _idle_tween.play()
	)

# ---------------------------------------------------------------------------
# EXTERNAL API METHODS & PROCEDURAL MODIFIERS
# ---------------------------------------------------------------------------
func set_monster(monster_data: Dictionary) -> void:
	var species_id: String = monster_data.get("speciesId", "chicken")
	var stage_id: String = monster_data.get("stageId", "stage_3")
	var morph_id: String = monster_data.get("morphId", "")
	var sprite_path: String = _resolve_sprite_path(species_id, stage_id, morph_id)
	var texture: Texture2D = load(sprite_path)
	
	if texture:
		_body_sprite.texture = texture
		_body_sprite.modulate = Color.WHITE
	else:
		_body_sprite.texture = load("res://assets/sprites/chicken/body.png")
	
	equip_cosmetic("head", monster_data.get("equippedHeadId", ""))
	equip_cosmetic("face", monster_data.get("equippedFaceId", ""))
	equip_cosmetic("body", monster_data.get("equippedBodyId", ""))

func _resolve_sprite_path(species_id: String, stage_id: String, morph_id: String) -> String:
	var morph: String = "default" if morph_id.is_empty() else morph_id
	var stage: String = _get_stage_name(stage_id)
	return "res://assets/monsters/%s/%s_%s.png" % [species_id, morph, stage]

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0": return "egg"
		"stage_1": return "baby"
		"stage_2": return "kid"
		"stage_3": return "adult"
		"stage_4": return "elder"
		_: return "adult"

func equip_cosmetic(slot: String, cosmetic_id: String) -> void:
	var slot_sprite: Sprite2D = null
	match slot:
		"head": slot_sprite = _head_slot_sprite
		"face": slot_sprite = _face_slot_sprite
		"body": slot_sprite = _body_slot_sprite

	if not slot_sprite: return
	if cosmetic_id.is_empty():
		slot_sprite.texture = null
		slot_sprite.modulate = Color.TRANSPARENT
		return

	var cosmetic_path: String = "res://data/cosmetics/%s.tres" % cosmetic_id
	var cosmetic_resource: Resource = load(cosmetic_path)
	if cosmetic_resource and "spritePath" in cosmetic_resource:
		slot_sprite.texture = load(cosmetic_resource.spritePath)
	else:
		slot_sprite.texture = load("res://assets/cosmetics/%s/%s.png" % [slot, cosmetic_id])
	
	if slot_sprite.texture:
		slot_sprite.modulate = Color.WHITE

func set_face_expression(expression_key: String) -> void:
	_set_expression(expression_key)
