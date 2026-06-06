extends Node2D

# Expanded to cover your requested states and structural animations
enum BlobEmotion {
	# --- BASE EMOTIONS ---
	IDLE, HAPPY, SURPRISED, SAD, ANGRY, SLEEPY, SLEEPING, WINKING, EXCITED, SMIRK, BLINK,

	# --- STATE & ENVIRONMENT OVERRIDES ---
	LOW_POWER,
	DAMAGED,
	OVERHEAT,
	CHARGING,
	MAINTENANCE_COMPLETE,
	SOFTWARE_DEBUGGED,
	PETTED,
	COMBAT_MODE,
	VICTORY,
	DEFEAT
}

# --- NODE REFERENCES ---
@onready var body_bone: Bone2D = $Skeleton2D/BodyBone2D
@onready var left_leg_bone: Bone2D = $Skeleton2D/BodyBone2D/LeftLegBone2D
@onready var right_leg_bone: Bone2D = $Skeleton2D/BodyBone2D/RightLegBone2D

@onready var body: Sprite2D = $Skeleton2D/BodyBone2D/Body
@onready var left_eye: Sprite2D = $Skeleton2D/BodyBone2D/HeadBone/LeftEye
@onready var right_eye: Sprite2D = $Skeleton2D/BodyBone2D/HeadBone/RightEye
@onready var mouth: Sprite2D = $Skeleton2D/BodyBone2D/HeadBone/Mouth

@onready var arm_left_bone: Bone2D = $Skeleton2D/BodyBone2D/ArmLeftBone
@onready var arm_right_bone: Bone2D = $Skeleton2D/BodyBone2D/ArmRightBone

@export_group("Expression System")
@export var base_emotion: BlobEmotion = BlobEmotion.IDLE:
	set(value):
		base_emotion = value
		if is_node_ready() and not _is_playing_action:
			_apply_emotion(base_emotion)

@export_group("Idle Animation Parameters")
@export var idle_speed: float = 4.5
@export var breath_amplitude: float = 0.018
@export var foot_bob_amplitude: float = 0

signal clicked_on_blob

# System State Tracking
var current_emotion: BlobEmotion = BlobEmotion.IDLE
var time: float = 0.0
var fl_foot_start_y: float
var fr_foot_start_y: float

# Internal Controllers
var _is_playing_action: bool = false
var _action_timer: float = 0.0
var _ambient_timer: float = 0.0
var _blink_duration: float = 0.12

# Action States
var is_walking: bool = false
var walk_speed_modifier: float = 12.0
var target_velocity_x: float = 0.0

var is_jumping: bool = false
var jump_time: float = 0.0
var jump_duration: float = 0.6
var jump_height_peak: float = -120.0

# Procedural Math Vectors
var _touch_bounce_y: float = 0.0
var _touch_squash_mod: Vector2 = Vector2.ONE
var _state_body_offset_y: float = 0.0

# Procedural Face & Bone Target Transforms
var target_eye_scale_y: float = 1.0
var target_left_eye_scale_x: float = 1.0
var target_right_eye_scale_x: float = 1.0
var target_mouth_scale: Vector2 = Vector2.ONE
var target_face_offset: Vector2 = Vector2.ZERO

var target_arm_l_rot: float = 0.0
var target_arm_r_rot: float = 0.0
var target_arm_l_pos: Vector2 = Vector2.ZERO
var target_arm_r_pos: Vector2 = Vector2.ZERO

# Baselines Cached at Start
var base_left_eye_scale: Vector2
var base_right_eye_scale: Vector2
var base_mouth_scale: Vector2
var base_arm_l_pos: Vector2
var base_arm_r_pos: Vector2

# Texture Atlas Clipping Pools (Fixed Initialization Syntax Error)
var eye_regions: Dictionary = {
	BlobEmotion.IDLE:                 {"left": Rect2(245, 62, 161, 74), "right": Rect2(245, 62, 161, 74)},
	BlobEmotion.HAPPY:                {"left": Rect2(535, 242, 145, 88), "right": Rect2(535, 242, 145, 88)},
	BlobEmotion.SURPRISED:            {"left": Rect2(63,607,132,130), "right": Rect2(63,607,132,130)},
	BlobEmotion.SAD:                  {"left": Rect2(545, 59, 133, 88), "right": Rect2(725, 59, 134, 89)},
	BlobEmotion.ANGRY:                {"left": Rect2(54, 234, 145, 109), "right": Rect2(256, 234, 146, 109)},
	BlobEmotion.SLEEPY:               {"left": Rect2(988, 55, 169, 86), "right": Rect2(1196, 60, 160, 80)},
	BlobEmotion.SLEEPING:             {"left": Rect2(525,607,144,121), "right": Rect2(725,615,157,126)},
	BlobEmotion.WINKING:              {"left": Rect2(994,424,158,126), "right": Rect2(245, 62, 161, 74)},
	BlobEmotion.EXCITED:              {"left": Rect2(245, 62, 161, 74), "right": Rect2(245, 62, 161, 74)},
	BlobEmotion.SMIRK:                {"left": Rect2(54, 234, 145, 109), "right": Rect2(256, 234, 146, 109)},
	BlobEmotion.BLINK:                {"left": Rect2(994,424,158,126), "right": Rect2(1194,423,156 ,126)},

	BlobEmotion.LOW_POWER:            {"left": Rect2(545, 59, 133, 88), "right": Rect2(725, 59, 134, 89)},
	BlobEmotion.DAMAGED:              {"left": Rect2(988, 55, 169, 86), "right": Rect2(1196, 60, 160, 80)},
	BlobEmotion.OVERHEAT:             {"left": Rect2(54, 234, 145, 109), "right": Rect2(256, 234, 146, 109)},
	BlobEmotion.CHARGING:             {"left": Rect2(535, 242, 145, 88), "right": Rect2(535, 242, 145, 88)},
	BlobEmotion.MAINTENANCE_COMPLETE: {"left": Rect2(993,243,158,83), "right": Rect2(993,243,158,83)},
	BlobEmotion.SOFTWARE_DEBUGGED:    {"left": Rect2(45,441,158,77), "right": Rect2(45,441,158,77)},
	BlobEmotion.PETTED:               {"left": Rect2(543,424,135,114), "right": Rect2(543,424,135,114)},
	BlobEmotion.COMBAT_MODE:          {"left": Rect2(994,424,158,126), "right": Rect2(1194,423,156 ,126)},
	BlobEmotion.VICTORY:              {"left": Rect2(63,607,132,130), "right": Rect2(63,607,132,130)},
	BlobEmotion.DEFEAT:               {"left": Rect2(525,607,144,121), "right": Rect2(725,615,157,126)}
}

var mouth_regions: Dictionary = {
	BlobEmotion.IDLE:                 Rect2(69,39,305,112),
	BlobEmotion.HAPPY:                Rect2(1022,203,331,147),
	BlobEmotion.SURPRISED:            Rect2(83,605,288,135),
	BlobEmotion.SAD:                  Rect2(551,45,308,106),
	BlobEmotion.ANGRY:                Rect2(85,203,283,148),
	BlobEmotion.SLEEPY:               Rect2(551,45,308,106),
	BlobEmotion.SLEEPING:             Rect2(554,609,299,130),
	BlobEmotion.EXCITED:              Rect2(83,605,288,135),
	BlobEmotion.WINKING:              Rect2(69,39,305,112),
	BlobEmotion.SMIRK:                Rect2(76,423,310,117),
	BlobEmotion.BLINK:                Rect2(69,39,305,112),

	BlobEmotion.LOW_POWER:            Rect2(551,45,308,106),
	BlobEmotion.DAMAGED:              Rect2(1011,37,319,117),
	BlobEmotion.OVERHEAT:             Rect2(85,203,283,148),
	BlobEmotion.CHARGING:             Rect2(549,231,303,119),
	BlobEmotion.MAINTENANCE_COMPLETE: Rect2(1022,203,331,147),
	BlobEmotion.SOFTWARE_DEBUGGED:    Rect2(76,423,310,117),
	BlobEmotion.PETTED:               Rect2(659,410,126,122),
	BlobEmotion.COMBAT_MODE:          Rect2(1021,453,306,49),
	BlobEmotion.VICTORY:              Rect2(83,605,288,135),
	BlobEmotion.DEFEAT:               Rect2(554,609,299,130)
}

func _ready() -> void:
	fl_foot_start_y = left_leg_bone.position.y
	fr_foot_start_y = right_leg_bone.position.y

	base_left_eye_scale = left_eye.scale
	base_right_eye_scale = right_eye.scale
	base_mouth_scale = mouth.scale

	base_arm_l_pos = arm_left_bone.position
	base_arm_r_pos = arm_right_bone.position

	current_emotion = base_emotion
	_apply_emotion(current_emotion)
	_reset_ambient_timer()

func _process(delta: float) -> void:
	time += delta * idle_speed

	_update_timers(delta)
	_handle_procedural_actions(delta)
	_animate_mesh(delta)

func _update_timers(delta: float) -> void:
	if _is_playing_action:
		_action_timer -= delta
		if _action_timer <= 0.0:
			_is_playing_action = false
			_apply_emotion(base_emotion)

	var behaves_ambiently = current_emotion in [BlobEmotion.IDLE, BlobEmotion.HAPPY, BlobEmotion.SLEEPY, BlobEmotion.SOFTWARE_DEBUGGED, BlobEmotion.COMBAT_MODE]
	if not _is_playing_action and behaves_ambiently and not is_walking:
		_ambient_timer -= delta
		if _ambient_timer <= 0.0:
			_trigger_ambient_event()

func _handle_procedural_actions(delta: float) -> void:
	if is_walking:
		position.x += target_velocity_x * delta
		var lean_angle = deg_to_rad(6.0) * (1.0 if target_velocity_x > 0 else -1.0)
		body_bone.rotation = lerp(body_bone.rotation, lean_angle, delta * 8.0)

		var arm_swing = sin(time * 2.5) * deg_to_rad(15.0)
		target_arm_l_rot = arm_swing
		target_arm_r_rot = -arm_swing
	else:
		body_bone.rotation = lerp(body_bone.rotation, 0.0, delta * 10.0)

	if is_jumping:
		jump_time += delta
		var t = jump_time / jump_duration

		if t >= 1.0:
			is_jumping = false
			_touch_squash_mod = Vector2(1.25, 0.75)
			_touch_bounce_y = 10.0
			if not _is_playing_action:
				_apply_emotion(base_emotion)
		else:
			var arc_y = 4.0 * jump_height_peak * t * (1.0 - t)
			body_bone.position.y = arc_y

			if t < 0.3:
				_touch_squash_mod = Vector2(0.85, 1.2)
			elif t > 0.7:
				_touch_squash_mod = Vector2(0.9, 1.15)
			else:
				_touch_squash_mod = Vector2(1.05, 0.95)

func _animate_mesh(delta: float) -> void:
	var current_amplitude = breath_amplitude
	var current_speed = idle_speed

	match current_emotion:
		BlobEmotion.SLEEPING, BlobEmotion.LOW_POWER:
			current_amplitude *= 0.3
			current_speed *= 0.4
		BlobEmotion.OVERHEAT:
			current_amplitude *= 2.5
			current_speed *= 3.0
		BlobEmotion.COMBAT_MODE:
			current_amplitude *= 0.6
			current_speed *= 1.5
		BlobEmotion.EXCITED, BlobEmotion.VICTORY, BlobEmotion.PETTED, is_walking:
			current_amplitude *= 1.6
			current_speed *= 1.8
		BlobEmotion.DAMAGED, BlobEmotion.DEFEAT:
			current_amplitude *= 0.0
			current_speed *= 0.0

	var mod_time = time * (current_speed / idle_speed)

	_touch_bounce_y = lerp(_touch_bounce_y, 0.0, delta * 8.0)
	_touch_squash_mod = lerp(_touch_squash_mod, Vector2.ONE, delta * 10.0)

	var scale_y: float = (1.0 + (sin(mod_time) * current_amplitude)) * _touch_squash_mod.y
	var scale_x: float = (1.0 - (sin(mod_time) * (current_amplitude * 0.6))) * _touch_squash_mod.x

	body_bone.scale = Vector2(scale_x, scale_y)

	if not is_jumping:
		var vibration = 0.0
		if current_emotion == BlobEmotion.OVERHEAT:
			vibration = randf_range(-1.5, 1.5)
		body_bone.position.y = (sin(mod_time) * 3.0) + _touch_bounce_y + _state_body_offset_y + vibration

	if is_walking:
		var walk_cycle = time * 2.2
		left_leg_bone.position.y = fl_foot_start_y + (sin(walk_cycle) * foot_bob_amplitude * 4.0)
		left_leg_bone.position.x = -1.0 + (cos(walk_cycle) * 12.0)

		right_leg_bone.position.y = fr_foot_start_y + (-sin(walk_cycle) * foot_bob_amplitude * 4.0)
		right_leg_bone.position.x = (cos(walk_cycle + PI) * 12.0)
	elif is_jumping:
		var t = jump_time / jump_duration
		if t < 0.5:
			left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y - 15.0, delta * 12.0)
			right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y - 15.0, delta * 12.0)
		else:
			left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y + 10.0, delta * 15.0)
			right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y + 10.0, delta * 15.0)
	else:
		match current_emotion:
			BlobEmotion.DAMAGED, BlobEmotion.DEFEAT:
				left_leg_bone.position.x = lerp(left_leg_bone.position.x, -12.0, delta * 8.0)
				right_leg_bone.position.x = lerp(right_leg_bone.position.x, 12.0, delta * 8.0)
				left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y - 4.0, delta * 8.0)
				right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y - 4.0, delta * 8.0)
			BlobEmotion.CHARGING:
				left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y, delta * 8.0)
				right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y, delta * 8.0)
				left_leg_bone.position.x = lerp(left_leg_bone.position.x, 0.0, delta * 8.0)
				right_leg_bone.position.x = lerp(right_leg_bone.position.x, 0.0, delta * 8.0)
			_:
				left_leg_bone.position.y = fl_foot_start_y + (cos(mod_time) * foot_bob_amplitude)
				right_leg_bone.position.y = fr_foot_start_y + (sin(mod_time) * foot_bob_amplitude)
				left_leg_bone.position.x = lerp(left_leg_bone.position.x, -1.0, delta * 10.0)
				right_leg_bone.position.x = lerp(right_leg_bone.position.x, 0.0, delta * 10.0)

	arm_left_bone.rotation = lerp(arm_left_bone.rotation, target_arm_l_rot, delta * 10.0)
	arm_right_bone.rotation = lerp(arm_right_bone.rotation, target_arm_r_rot, delta * 10.0)
	arm_left_bone.position = lerp(arm_left_bone.position, base_arm_l_pos + target_arm_l_pos, delta * 10.0)
	arm_right_bone.position = lerp(arm_right_bone.position, base_arm_r_pos + target_arm_r_pos, delta * 10.0)

	var lerp_speed: float = 25.0 if current_emotion in [BlobEmotion.BLINK, BlobEmotion.SLEEPING, BlobEmotion.CHARGING] else 12.0

	left_eye.scale.y = lerp(left_eye.scale.y, base_left_eye_scale.y * target_eye_scale_y, delta * lerp_speed)
	left_eye.scale.x = lerp(left_eye.scale.x, base_left_eye_scale.x * target_left_eye_scale_x, delta * lerp_speed)
	right_eye.scale.y = lerp(right_eye.scale.y, base_right_eye_scale.y * target_eye_scale_y, delta * lerp_speed)
	right_eye.scale.x = lerp(right_eye.scale.x, base_right_eye_scale.x * target_left_eye_scale_x, delta * lerp_speed)

	mouth.scale = lerp(mouth.scale, base_mouth_scale * target_mouth_scale, delta * 12.0)

	left_eye.position.x = lerp(left_eye.position.x, -30.0 + target_face_offset.x, delta * 10.0)
	right_eye.position.x = lerp(right_eye.position.x, 34.0 + target_face_offset.x, delta * 10.0)
	mouth.position.x = lerp(mouth.position.x, 2.0 + target_face_offset.x, delta * 10.0)

	left_leg_bone.position.x = lerp(left_leg_bone.position.x, -12.0, delta * 8.0)
	right_leg_bone.position.x = lerp(right_leg_bone.position.x, 12.0, delta * 8.0)
	left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y - 4.0, delta * 8.0)
	right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y - 4.0, delta * 8.0)

func _apply_emotion(emotion: BlobEmotion) -> void:
	current_emotion = emotion
	if not is_inside_tree(): return

	_setup_expression_modifiers(emotion)

	if eye_regions.has(emotion) and left_eye and right_eye:
		left_eye.region_rect = eye_regions[emotion]["left"]
		right_eye.region_rect = eye_regions[emotion]["right"]

	if mouth_regions.has(emotion) and mouth:
		mouth.region_rect = mouth_regions[emotion]

func _setup_expression_modifiers(emotion: BlobEmotion) -> void:
	target_eye_scale_y = 1.0
	target_left_eye_scale_x = 1.0
	target_right_eye_scale_x = 1.0
	target_mouth_scale = Vector2.ONE
	target_face_offset = Vector2.ZERO
	_state_body_offset_y = 0.0

	target_arm_l_rot = 0.0
	target_arm_r_rot = 0.0
	target_arm_l_pos = Vector2.ZERO
	target_arm_r_pos = Vector2.ZERO

	match emotion:
		BlobEmotion.LOW_POWER:
			_state_body_offset_y = 15.0
			target_arm_l_rot = deg_to_rad(12.0)
			target_arm_r_rot = deg_to_rad(-12.0)

		# FIXED DAMAGED: Now utilizes simple strings inside the matching engine scope safely
		BlobEmotion.DAMAGED:
			target_face_offset.y = 4.0
			_state_body_offset_y = 22.0
			target_arm_l_rot = deg_to_rad(-25.0)
			target_arm_r_rot = deg_to_rad(10.0)
			target_arm_l_pos = Vector2(-4, 6)

		BlobEmotion.OVERHEAT:
			target_left_eye_scale_x = 1.1
			target_right_eye_scale_x = 1.1
			_state_body_offset_y = -5.0
			target_arm_l_rot = deg_to_rad(-45.0)
			target_arm_r_rot = deg_to_rad(45.0)

		BlobEmotion.CHARGING:
			#target_eye_scale_y = 0.05
			target_mouth_scale = Vector2(0.6, 0.7)
			_state_body_offset_y = 5.0

		# MAINTENANCE COMPLETE
		BlobEmotion.MAINTENANCE_COMPLETE:
			_touch_squash_mod = Vector2(0.85, 1.15)

		# SOFTWARE DEBUGGED
		BlobEmotion.SOFTWARE_DEBUGGED:
			target_face_offset.x = 4.0

		# PETTED / AFFECTION
		BlobEmotion.PETTED:
			_state_body_offset_y = 6.0
			target_mouth_scale = Vector2(1, 2)
			target_arm_l_rot = deg_to_rad(-35.0)
			target_arm_r_rot = deg_to_rad(35.0)

		# FOCUS / COMBAT MODE
		BlobEmotion.COMBAT_MODE:
			_state_body_offset_y = -8.0
			target_arm_l_rot = deg_to_rad(-60.0)
			target_arm_r_rot = deg_to_rad(60.0)

		# VICTORY / HIGH SCORE
		BlobEmotion.VICTORY:
			#target_eye_scale_y = 1.3
			target_face_offset.y = -10.0
			target_arm_l_rot = deg_to_rad(-140.0)
			target_arm_r_rot = deg_to_rad(140.0)

		# DEFEAT / CRASH
		BlobEmotion.DEFEAT:
			_state_body_offset_y = 28.0
			target_arm_l_rot = deg_to_rad(85.0)
			target_arm_r_rot = deg_to_rad(-85.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_click_pos = body_bone.to_local(event.position)
		if local_click_pos.length() < 160.0:
			_on_blob_tapped()

# --- SYSTEM CONTROLLER ACTIONS ---

func set_walking(enable: bool, speed_pixels_per_sec: float = 120.0) -> void:
	is_walking = enable
	target_velocity_x = speed_pixels_per_sec if enable else 0.0

func play_jump_action(height: float = -150.0, duration: float = 0.65) -> void:
	if is_jumping: return
	is_jumping = true
	jump_time = 0.0
	jump_duration = duration
	jump_height_peak = height
	play_action_emotion(BlobEmotion.SURPRISED, duration)

func play_action_emotion(action_emotion: BlobEmotion, duration: float = 1.5) -> void:
	_is_playing_action = true
	_action_timer = duration
	_apply_emotion(action_emotion)

func change_base_emotion(new_emotion: BlobEmotion) -> void:
	base_emotion = new_emotion

func _on_blob_tapped() -> void:
	if base_emotion == BlobEmotion.IDLE:
		play_action_emotion(BlobEmotion.PETTED, 1.2)
		_touch_squash_mod = Vector2(1.15, 0.85)
		_touch_bounce_y = 6.0
	else:
		_touch_squash_mod = Vector2(0.9, 1.1)
		_touch_bounce_y = -15.0
	clicked_on_blob.emit()

func _trigger_ambient_event() -> void:
	if base_emotion != BlobEmotion.IDLE and base_emotion != BlobEmotion.SLEEPY:
		_reset_ambient_timer()
		return

	var roll = randf()
	if roll < 0.50:
		_apply_emotion(BlobEmotion.BLINK)
		await get_tree().create_timer(_blink_duration).timeout
		if not _is_playing_action:
			_apply_emotion(base_emotion)
	elif roll < 0.75:
		_apply_emotion(BlobEmotion.SURPRISED)
		await get_tree().create_timer(1.8).timeout
		if not _is_playing_action:
			_apply_emotion(base_emotion)
	else:
		var choice = BlobEmotion.WINKING if randf() > 0.5 else BlobEmotion.SMIRK
		_apply_emotion(choice)
		await get_tree().create_timer(2.0).timeout
		if not _is_playing_action:
			_apply_emotion(base_emotion)

	_reset_ambient_timer()

func _reset_ambient_timer() -> void:
	_ambient_timer = randf_range(4.0, 9.0)
