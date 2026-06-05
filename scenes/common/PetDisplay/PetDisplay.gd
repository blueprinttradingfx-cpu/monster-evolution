extends SubViewportContainer
class_name PetDisplay

# PetDisplay - Fully operational, interactive 2D modular puppet system.
# Drives breathing loops, action triggers, expressions, and click-and-drag physics.

signal monster_tapped()
signal monster_drag_started()
signal monster_drag_ended()

# --- Core Skeleton Links ---
@onready var _skeleton: Skeleton2D = $SubViewport/Monster2DScene/Skeleton2D
@onready var _body_bone: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/BodyBone
@onready var _head_bone: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone

# --- Limb Links (Hands and Feet) ---
@onready var _front_arm: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/FrontArmBone
@onready var _rear_arm: Bone2D    = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/RearArmBone
@onready var _front_leg: Bone2D   = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/FrontLegBone
@onready var _rear_leg: Bone2D    = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/RearLegBone
@onready var _front_forearm: Bone2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/FrontArmBone/FrontForearmBone
@onready var _rear_forearm: Bone2D  = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/RearArmBone/RearForearmBone

# --- Feature Layer Slots (Facial Expressions) ---
@onready var _body_sprite: Sprite2D       = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySprite
@onready var _head_sprite: Sprite2D       = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/HeadSprite
@onready var _eyes_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/EyesSlotSprite
@onready var _mouth_slot_sprite: Sprite2D = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/MouthSlotSprite

# --- Cosmetic Slot Links ---
@onready var _head_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/HeadSlotSprite
@onready var _face_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/HeadBone/FaceSlotSprite
@onready var _body_slot_sprite: Sprite2D  = $SubViewport/Monster2DScene/Skeleton2D/BodyBone/BodySlotSprite

# --- Interactive Drag & Physics State Settings ---
@export var follow_speed: float = 12.0
@export var drag_elasticity: float = 15.0

var _is_dragging: bool = false
var _drag_velocity: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _base_body_rest_pos: Vector2 = Vector2(128, 140)

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
			_eyes_slot_sprite.texture = load("res://assets/sprites/face/eyes_happy.png")
			_mouth_slot_sprite.texture = load("res://assets/sprites/face/mouth_smile.png")
		"sad", "sigh":
			_eyes_slot_sprite.texture = load("res://assets/sprites/face/eyes_closed.png")
			_mouth_slot_sprite.texture = load("res://assets/sprites/face/mouth_flat.png")
		"surprised", "dragged":
			_eyes_slot_sprite.texture = load("res://assets/sprites/face/eyes_wide.png")
			_mouth_slot_sprite.texture = load("res://assets/sprites/face/mouth_open.png")
		_: # Neutral baseline
			_eyes_slot_sprite.texture = load("res://assets/sprites/face/eyes_default.png")
			_mouth_slot_sprite.texture = load("res://assets/sprites/face/mouth_default.png")

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
	
	_body_bone.rotation = lerpf(_body_bone.rotation, travel_lean, 8.0 * delta)
	_head_bone.rotation = lerpf(_head_bone.rotation, -travel_lean * 0.5, 8.0 * delta)
	
	# Dual arm trailing logic: arms pull upward/backward during fall or drag velocity shifts
	_front_arm.rotation = lerpf(_front_arm.rotation, (PI / 2.0) + (travel_lean * 0.8), 8.0 * delta)
	_rear_arm.rotation = lerpf(_rear_arm.rotation, (-PI / 2.0) + (travel_lean * 0.8), 8.0 * delta)
	
	# Legs dangle downwards
	_front_leg.rotation = lerpf(_front_leg.rotation, -travel_lean * 0.3, 8.0 * delta)
	_rear_leg.rotation = lerpf(_rear_leg.rotation, -travel_lean * 0.3, 8.0 * delta)

func _play_drop_impact() -> void:
	if _action_tween: _action_tween.kill()
	_action_tween = create_tween()
	
	# Ground impact bounce and squash compression phase
	_action_tween.tween_property(_body_bone, "position", _base_body_rest_pos, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.3, 0.7), 0.15)
	_action_tween.parallel().tween_property(_body_bone, "rotation", 0.0, 0.15)
	
	# Reset arm/leg rotations back smoothly
	_action_tween.parallel().tween_property(_front_arm, "rotation", 0.0, 0.15)
	_action_tween.parallel().tween_property(_rear_arm, "rotation", 0.0, 0.15)
	
	# Elastic rebound back to rest state
	_action_tween.chain().tween_property(_body_bone, "scale", Vector2(0.95, 1.05), 0.15)
	_action_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.1)
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
	_idle_tween.tween_property(_body_bone, "scale", Vector2(1.03, 0.96), 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", -2.5, 1.1)
	
	_idle_tween.tween_property(_body_bone, "scale", Vector2(0.98, 1.02), 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(_head_bone, "position:y", 2.5, 1.1)

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

func _action_wave_old() -> void:
	if _idle_tween: _idle_tween.pause()
	_set_expression("happy")
	
	var wave_tween := create_tween()
	# Front arm waves high, rear arm waves in dynamic offset secondary rotation
	wave_tween.tween_property(_front_arm, "rotation", -1.2, 0.2).set_trans(Tween.TRANS_SINE)
	wave_tween.parallel().tween_property(_rear_arm, "rotation", 0.4, 0.2).set_trans(Tween.TRANS_SINE)
	
	wave_tween.chain().tween_property(_front_arm, "rotation", -1.7, 0.12)
	wave_tween.tween_property(_front_arm, "rotation", -1.0, 0.12)
	wave_tween.tween_property(_front_arm, "rotation", -1.7, 0.12)
	wave_tween.tween_property(_front_arm, "rotation", -1.0, 0.12)
	
	wave_tween.chain().tween_property(_front_arm, "rotation", 0.0, 0.2)
	wave_tween.parallel().tween_property(_rear_arm, "rotation", 0.0, 0.2)
	
	wave_tween.tween_callback(func():
		_set_expression("neutral")
		if _idle_tween: _idle_tween.play()
	)

func _action_wave() -> void:
	if _idle_tween: _idle_tween.pause()
	_set_expression("happy")
	
	var wave_tween := create_tween()
	
	# --- PHASE 1: LIFT ARM & SNAP HAND UPUP ---
	# Shoulder rotates up/left (-1.2), Forearm counter-rotates up/right (1.2) to stay vertical
	wave_tween.tween_property(_front_arm, "rotation", -1.2, 0.2).set_trans(Tween.TRANS_SINE)
	wave_tween.parallel().tween_property(_front_forearm, "rotation", 1.2, 0.2).set_trans(Tween.TRANS_SINE)
	
	# --- PHASE 2: THE FANTASTIC FLAP LOOP ---
	# The shoulder stays still while ONLY the forearm/hand snaps back and forth rapidly
	wave_tween.chain().tween_property(_front_forearm, "rotation", 0.6, 0.1)  # Tilt left
	wave_tween.tween_property(_front_forearm, "rotation", 1.6, 0.1)          # Flap right
	wave_tween.tween_property(_front_forearm, "rotation", 0.6, 0.1)          # Tilt left
	wave_tween.tween_property(_front_forearm, "rotation", 1.6, 0.1)          # Flap right
	
	# --- PHASE 3: RETURN TO REST ---
	# Bring both segments smoothly back down to 0
	wave_tween.chain().tween_property(_front_arm, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	wave_tween.parallel().tween_property(_front_forearm, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	wave_tween.parallel().tween_property(_rear_arm, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	wave_tween.tween_callback(func():
		_set_expression("neutral")
		if _idle_tween: _idle_tween.play()
	)

func _action_sigh() -> void:
	if _idle_tween: _idle_tween.pause()
	_set_expression("sigh")
	
	var sigh_tween := create_tween()
	# Heavy, tired breath droop
	sigh_tween.tween_property(_body_bone, "scale", Vector2(0.96, 0.92), 0.6).set_trans(Tween.TRANS_SINE)
	sigh_tween.parallel().tween_property(_head_bone, "position:y", 6.0, 0.6)
	sigh_tween.parallel().tween_property(_front_arm, "rotation", 0.2, 0.6)
	sigh_tween.parallel().tween_property(_rear_arm, "rotation", -0.2, 0.6)
	
	# Smooth reinflation back to baseline
	sigh_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.5)
	sigh_tween.parallel().tween_property(_head_bone, "position:y", 0.0, 0.5)
	sigh_tween.parallel().tween_property(_front_arm, "rotation", 0.0, 0.5)
	sigh_tween.parallel().tween_property(_rear_arm, "rotation", 0.0, 0.5)
	
	# Restore state
	sigh_tween.tween_callback(func():
		_set_expression("neutral")
		if _idle_tween: _idle_tween.play()
	)

func _action_jump() -> void:
	if _idle_tween: _idle_tween.pause()
	
	var jump_tween := create_tween()
	# Crouch and load energy phase
	jump_tween.tween_property(_body_bone, "position:y", _base_body_rest_pos.y + 12.0, 0.15).set_trans(Tween.TRANS_QUAD)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.15, 0.85), 0.15)
	
	# Ascent lift-off explosion phase
	jump_tween.chain().tween_property(_body_bone, "position:y", _base_body_rest_pos.y - 45.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(0.88, 1.15), 0.25)
	
	# Taper limbs to suggest airborne physics suspension
	jump_tween.parallel().tween_property(_front_leg, "rotation", 0.4, 0.2)
	jump_tween.parallel().tween_property(_rear_leg, "rotation", -0.4, 0.2)
	jump_tween.parallel().tween_property(_front_arm, "rotation", -0.5, 0.2)
	jump_tween.parallel().tween_property(_rear_arm, "rotation", 0.5, 0.2)
	
	# Descent falling and hard floor landing phase
	jump_tween.chain().tween_property(_body_bone, "position:y", _base_body_rest_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	jump_tween.parallel().tween_property(_body_bone, "scale", Vector2(1.2, 0.8), 0.2)
	jump_tween.parallel().tween_property(_front_leg, "rotation", 0.0, 0.1)
	jump_tween.parallel().tween_property(_rear_leg, "rotation", 0.0, 0.1)
	jump_tween.parallel().tween_property(_front_arm, "rotation", 0.0, 0.1)
	jump_tween.parallel().tween_property(_rear_arm, "rotation", 0.0, 0.1)
	
	# Rebound reset back to breathing pose
	jump_tween.chain().tween_property(_body_bone, "scale", Vector2(1.0, 1.0), 0.15)
	jump_tween.tween_callback(func():
		if _idle_tween: _idle_tween.play()
	)

# ---------------------------------------------------------------------------
# MONSTER DATA & ASSET LOADING
# ---------------------------------------------------------------------------
func set_monster(monster_data: Dictionary) -> void:
	# Load base monster sprite
	var species_id: String = monster_data.get("speciesId", "dino")
	var stage_id: String = monster_data.get("stageId", "stage_3")
	var morph_id: String = monster_data.get("morphId", "")
	var sprite_path: String = _resolve_sprite_path(species_id, stage_id, morph_id)
	var texture: Texture2D = load(sprite_path)
	
	if texture:
		_body_sprite.texture = texture
		_body_sprite.modulate = Color.WHITE
	else:
		_body_sprite.texture = load("res://assets/sprites/dino.png")
	
	# Load cosmetics
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

# ---------------------------------------------------------------------------
# PROCEDURAL COSMETIC EQUIPPER LINK
# ---------------------------------------------------------------------------
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

	# Try loading from Cosmetic resource first
	var cosmetic_path: String = "res://data/cosmetics/%s.tres" % cosmetic_id
	var cosmetic_resource: Resource = load(cosmetic_path)
	if cosmetic_resource and cosmetic_resource is Cosmetic:
		slot_sprite.texture = load(cosmetic_resource.spritePath)
	else:
		# Fallback to direct PNG path
		slot_sprite.texture = load("res://assets/cosmetics/%s/%s.png" % [slot, cosmetic_id])
	
	if slot_sprite.texture:
		slot_sprite.modulate = Color.WHITE
