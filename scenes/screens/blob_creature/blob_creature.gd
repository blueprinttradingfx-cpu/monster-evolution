extends Node2D

enum BlobEmotion { IDLE, HAPPY, SURPRISED, SAD, ANGRY, SLEEPY, SLEEPING, WINKING, EXCITED, SMIRK, BLINK }

# --- FIXED NODE REFERENCES ---
# Explicitly matching your new Skeleton2D hierarchy
@onready var body_bone: Bone2D = $Skeleton2D/BodyBone2D
@onready var left_leg_bone: Bone2D = $Skeleton2D/BodyBone2D/FLLegBone2D
@onready var right_leg_bone: Bone2D = $Skeleton2D/BodyBone2D/FRLegBone2D

@onready var body: Sprite2D = $Skeleton2D/BodyBone2D/Body
@onready var left_eye: Sprite2D = $Skeleton2D/BodyBone2D/Body/LeftEye
@onready var right_eye: Sprite2D = $Skeleton2D/BodyBone2D/Body/RightEye
@onready var mouth: Sprite2D = $Skeleton2D/BodyBone2D/Body/Mouth

@export_group("Expression System")
@export var base_emotion: BlobEmotion = BlobEmotion.IDLE:
	set(value):
		base_emotion = value
		if is_node_ready() and not _is_playing_action:
			_apply_emotion(base_emotion)

@export_group("Idle Animation")
@export var idle_speed: float = 4.5
@export var breath_amplitude: float = 0.018
@export var foot_bob_amplitude: float = 1.8

signal clicked_on_blob

# System State Variables
var current_emotion: BlobEmotion = BlobEmotion.IDLE
var time: float = 0.0
var fl_foot_start_y: float
var fr_foot_start_y: float

# Controller Tracking
var _is_playing_action: bool = false
var _action_timer: float = 0.0
var _ambient_timer: float = 0.0
var _blink_duration: float = 0.12

# Action Engine State Tracking
var is_walking: bool = false
var walk_speed_modifier: float = 12.0
var target_velocity_x: float = 0.0

var is_jumping: bool = false
var jump_time: float = 0.0
var jump_duration: float = 0.6
var jump_height_peak: float = -120.0

# Procedural Modifiers
var _touch_bounce_y: float = 0.0
var _touch_squash_mod: Vector2 = Vector2.ONE

# Procedural Face Targets
var target_eye_scale_y: float = 1.0
var target_left_eye_scale_x: float = 1.0
var target_right_eye_scale_x: float = 1.0
var target_mouth_scale: Vector2 = Vector2.ONE
var target_face_offset: Vector2 = Vector2.ZERO

# Design Space Caching
var base_left_eye_scale: Vector2
var base_right_eye_scale: Vector2
var base_mouth_scale: Vector2

# Texture Slicing Coordinate Pools
var eye_regions: Dictionary = {
	BlobEmotion.IDLE:      {"left": Rect2(117.5, 41, 181.5, 160.4), "right": Rect2(428, 36.5, 182, 168)},
	BlobEmotion.HAPPY:     {"left": Rect2(790.0, 64.5, 203.0, 105.0), "right": Rect2(1129.0, 64.5, 203.0, 105.0)},
	BlobEmotion.SURPRISED: {"left": Rect2(115, 220, 181, 173), "right": Rect2(429, 220, 181, 173)},
	BlobEmotion.SAD:       {"left": Rect2(809, 217, 193, 155), "right": Rect2(1128, 217, 193, 155)},
	BlobEmotion.ANGRY:     {"left": Rect2(108, 419, 230, 135), "right": Rect2(393, 419, 230, 135)},
	BlobEmotion.SLEEPY:    {"left": Rect2(809, 398, 194, 157), "right": Rect2(1126, 398, 194, 157)},
	BlobEmotion.SLEEPING:  {"left": Rect2(108, 593, 190, 118), "right": Rect2(423, 593, 190, 118)},
	BlobEmotion.WINKING:   {"left": Rect2(808, 591, 191, 114), "right": Rect2(1140, 566, 182, 166)},
	BlobEmotion.EXCITED:   {"left": Rect2(117.5, 41, 181.5, 160.4), "right": Rect2(428, 36.5, 182, 168)},
	BlobEmotion.SMIRK:     {"left": Rect2(108, 419, 230, 135), "right": Rect2(393, 419, 230, 135)},
	BlobEmotion.BLINK:     {"left": Rect2(108, 593, 190, 118), "right": Rect2(423, 593, 190, 118)},
}

var mouth_regions: Dictionary = {
	BlobEmotion.IDLE:      Rect2(86.1, 177.2, 182.5, 90.6),
	BlobEmotion.HAPPY:     Rect2(401, 142, 252, 145),
	BlobEmotion.SURPRISED: Rect2(811, 122, 140, 194),
	BlobEmotion.SAD:       Rect2(1145, 177, 168, 70),
	BlobEmotion.ANGRY:     Rect2(50, 472, 261, 191),
	BlobEmotion.SLEEPY:    Rect2(429, 561, 207, 49),
	BlobEmotion.SLEEPING:  Rect2(429, 561, 207, 49),
	BlobEmotion.EXCITED:   Rect2(754, 451, 255, 253),
	BlobEmotion.WINKING:   Rect2(86.1, 177.2, 182.5, 90.6),
	BlobEmotion.SMIRK:     Rect2(1114, 517, 238, 118),
	BlobEmotion.BLINK:     Rect2(86.1, 177.2, 182.5, 90.6),
}

func _ready() -> void:
	# Store bone baselines instead of sprite baselines
	fl_foot_start_y = left_leg_bone.position.y
	fr_foot_start_y = right_leg_bone.position.y
	
	base_left_eye_scale = left_eye.scale
	base_right_eye_scale = right_eye.scale
	base_mouth_scale = mouth.scale
	
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
	
	if not _is_playing_action and base_emotion != BlobEmotion.SLEEPING and not is_walking:
		_ambient_timer -= delta
		if _ambient_timer <= 0.0:
			_trigger_ambient_event()

func _handle_procedural_actions(delta: float) -> void:
	# Handle walking translation
	if is_walking:
		position.x += target_velocity_x * delta
		# Tilt the entire body slightly forward into the walk direction
		var lean_angle = deg_to_rad(6.0) * (1.0 if target_velocity_x > 0 else -1.0)
		body_bone.rotation = lerp(body_bone.rotation, lean_angle, delta * 8.0)
	else:
		body_bone.rotation = lerp(body_bone.rotation, 0.0, delta * 10.0)
		
	# Handle active jumping mechanics
	if is_jumping:
		jump_time += delta
		var t = jump_time / jump_duration
		
		if t >= 1.0:
			# Landing Impact
			is_jumping = false
			_touch_squash_mod = Vector2(1.25, 0.75) # Heavy landing flatten
			_touch_bounce_y = 10.0
			if not _is_playing_action:
				_apply_emotion(base_emotion)
		else:
			# Parabolic jump arc calculation: 4 * height * t * (1 - t)
			var arc_y = 4.0 * jump_height_peak * t * (1.0 - t)
			body_bone.position.y = arc_y
			
			# Stretch mid-air, squash slightly at peak apex
			if t < 0.3:
				_touch_squash_mod = Vector2(0.85, 1.2) # Launch stretch
			elif t > 0.7:
				_touch_squash_mod = Vector2(0.9, 1.15) # Preparing to land stretch
			else:
				_touch_squash_mod = Vector2(1.05, 0.95) # Apex float ball

func _animate_mesh(delta: float) -> void:
	var current_amplitude = breath_amplitude
	var current_speed = idle_speed
	
	if current_emotion == BlobEmotion.SLEEPING:
		current_amplitude *= 0.4
		current_speed *= 0.5
	elif current_emotion == BlobEmotion.EXCITED or is_walking:
		current_amplitude *= 1.6
		current_speed *= 1.8

	var mod_time = time * (current_speed / idle_speed)
	
	# Ease touch and jump math back to zero
	_touch_bounce_y = lerp(_touch_bounce_y, 0.0, delta * 8.0)
	_touch_squash_mod = lerp(_touch_squash_mod, Vector2.ONE, delta * 10.0)
	
	# Calculate global master squash scales
	var scale_y: float = (1.0 + (sin(mod_time) * current_amplitude)) * _touch_squash_mod.y
	var scale_x: float = (1.0 - (sin(mod_time) * (current_amplitude * 0.6))) * _touch_squash_mod.x
	
	# Pass transformations directly to the master Body Bone
	body_bone.scale = Vector2(scale_x, scale_y)
	
	if not is_jumping:
		body_bone.position.y = (sin(mod_time) * 3.0) + _touch_bounce_y

	# --- SYSTEM LEG MOTION PROCEDURES ---
	if is_walking:
		# Alternate legs back and forth smoothly using high frequency sine/cosine loops
		var walk_cycle = time * 2.2
		left_leg_bone.position.y = fl_foot_start_y + (sin(walk_cycle) * foot_bob_amplitude * 4.0)
		left_leg_bone.position.x = -1.0 + (cos(walk_cycle) * 12.0)
		
		right_leg_bone.position.y = fr_foot_start_y + (-sin(walk_cycle) * foot_bob_amplitude * 4.0)
		right_leg_bone.position.x = (cos(walk_cycle + PI) * 12.0)
	elif is_jumping:
		# Pull legs up into body tight while rising, extend downwards while falling
		var t = jump_time / jump_duration
		if t < 0.5:
			left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y - 15.0, delta * 12.0)
			right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y - 15.0, delta * 12.0)
		else:
			left_leg_bone.position.y = lerp(left_leg_bone.position.y, fl_foot_start_y + 10.0, delta * 15.0)
			right_leg_bone.position.y = lerp(right_leg_bone.position.y, fr_foot_start_y + 10.0, delta * 15.0)
		left_leg_bone.position.x = lerp(left_leg_bone.position.x, -1.0, delta * 10.0)
		right_leg_bone.position.x = lerp(right_leg_bone.position.x, 0.0, delta * 10.0)
	else:
		# Standard organic idling breathe loop
		left_leg_bone.position.y = fl_foot_start_y + (cos(mod_time) * foot_bob_amplitude)
		right_leg_bone.position.y = fr_foot_start_y + (sin(mod_time) * foot_bob_amplitude)
		left_leg_bone.position.x = lerp(left_leg_bone.position.x, -1.0, delta * 10.0)
		right_leg_bone.position.x = lerp(right_leg_bone.position.x, 0.0, delta * 10.0)

	# --- Face Interpolation Layer ---
	var lerp_speed: float = 25.0 if current_emotion == BlobEmotion.BLINK or current_emotion == BlobEmotion.SLEEPING else 12.0
	
	left_eye.scale.y = lerp(left_eye.scale.y, base_left_eye_scale.y * target_eye_scale_y, delta * lerp_speed)
	left_eye.scale.x = lerp(left_eye.scale.x, base_left_eye_scale.x * target_left_eye_scale_x, delta * lerp_speed)
	
	right_eye.scale.y = lerp(right_eye.scale.y, base_right_eye_scale.y * target_eye_scale_y, delta * lerp_speed)
	right_eye.scale.x = lerp(right_eye.scale.x, base_right_eye_scale.x * target_right_eye_scale_x, delta * lerp_speed)
	
	mouth.scale = lerp(mouth.scale, base_mouth_scale * target_mouth_scale, delta * 12.0)
	
	left_eye.position.x = lerp(left_eye.position.x, -60.0 + target_face_offset.x, delta * 10.0)
	right_eye.position.x = lerp(right_eye.position.x, 60.0 + target_face_offset.x, delta * 10.0)
	mouth.position.x = lerp(mouth.position.x, 1.0 + target_face_offset.x, delta * 10.0)

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

	match emotion:
		BlobEmotion.BLINK, BlobEmotion.SLEEPING:
			target_eye_scale_y = 0.1
		BlobEmotion.WINKING:
			target_right_eye_scale_x = 0.9
			target_eye_scale_y = 1.0
		BlobEmotion.SURPRISED:
			target_eye_scale_y = 1.2
			target_mouth_scale = Vector2(0.9, 1.2)
			target_face_offset.y = -5.0
		BlobEmotion.ANGRY:
			target_eye_scale_y = 0.9
			target_face_offset.x = randf_range(-4.0, 4.0)
		BlobEmotion.EXCITED:
			target_eye_scale_y = 1.1
			target_mouth_scale = Vector2(1.2, 1.2)
		BlobEmotion.SMIRK:
			target_mouth_scale = Vector2(1.1, 0.9)
			target_face_offset.x = 8.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_click_pos = body.to_local(event.position)
		if local_click_pos.length() < 160.0:
			_on_blob_tapped()

# --- NEW PUBLIC CONTROLLER API ACTIONS ---

## Triggers the procedural walk behavior. Set speed to 0 or call with false to stop walking.
func set_walking(enable: bool, speed_pixels_per_sec: float = 120.0) -> void:
	is_walking = enable
	target_velocity_x = speed_pixels_per_sec if enable else 0.0

## Commands the creature to perform an advanced physical jump action.
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

# --- INTERNAL ENGINES & EVENT HANDLERS ---
func _on_blob_tapped() -> void:
	# Keep the juicy visual squash impact when touched
	target_eye_scale_y = 0.2
	target_mouth_scale = Vector2(1.4, 0.3)
	_touch_squash_mod = Vector2(0.9, 1.1) 
	_touch_bounce_y = -15.0  

	# CRITICAL: Tell the current room that the blob was tapped!
	clicked_on_blob.emit()

func _on_blob_tapped_old() -> void:
	# If tapped while idling, add an interactive jump action!
	if not is_jumping and not is_walking:
		play_jump_action(-130.0, 0.6)
		return
		
	target_eye_scale_y = 0.2
	target_mouth_scale = Vector2(1.4, 0.3)
	
	var reactions = [BlobEmotion.HAPPY, BlobEmotion.SURPRISED, BlobEmotion.EXCITED, BlobEmotion.ANGRY, BlobEmotion.SMIRK]
	var selected_reaction = reactions[randi() % reactions.size()]
	
	if selected_reaction == BlobEmotion.ANGRY:
		_touch_squash_mod = Vector2(1.12, 0.88) 
		_touch_bounce_y = 8.0
		play_action_emotion(selected_reaction, 1.8)
	else:
		_touch_squash_mod = Vector2(0.9, 1.1) 
		_touch_bounce_y = -22.0
		play_action_emotion(selected_reaction, 1.5)

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
