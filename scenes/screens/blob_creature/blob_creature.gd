extends Node2D

# 1. Complete Emotion Set Enums
enum BlobEmotion { IDLE, HAPPY, SURPRISED, SAD, ANGRY, SLEEPY, SLEEPING, WINKING, EXCITED, SMIRK }

# 2. Node references explicitly matching your TSCN hierarchy
@onready var body: Sprite2D = $Body
@onready var left_eye: Sprite2D = $Body/LeftEye
@onready var right_eye: Sprite2D = $Body/RightEye
@onready var mouth: Sprite2D = $Body/Mouth
@onready var front_left_foot: Sprite2D = $FrontLeftFoot
@onready var front_right_foot: Sprite2D = $FrontRightFoot

@export_group("Expression System")
@export var current_emotion: BlobEmotion = BlobEmotion.IDLE:
	set(value):
		current_emotion = value
		if is_node_ready():
			_apply_emotion(value)

@export_group("Idle Animation")
@export var idle_speed: float = 4.5
@export var breath_amplitude: float = 0.04
@export var foot_bob_amplitude: float = 4.0

var time: float = 0.0
var fl_foot_start_y: float
var fr_foot_start_y: float

# 3. Comprehensive Mapping for all 8 Eyes States
# Format: Rect2(X_Position, Y_Position, Width, Height)
# NOTE: Update these coordinates to match the exact pixel positions in your eyes.png
var eye_regions: Dictionary = {
	BlobEmotion.IDLE: {
		"left": Rect2(117.5, 41, 181.5, 160.4), 
		"right": Rect2(428, 36.5, 182, 168)
	},
	BlobEmotion.HAPPY: {
		"left": Rect2(790.0, 64.5, 203.0, 105.0), # Crescent upward
		"right": Rect2(1129.0, 64.5, 203.0, 105.0)
	},
	BlobEmotion.SURPRISED: {
		"left": Rect2(115, 220, 181, 173), # Wide open, tiny pupils
		"right": Rect2(429, 220, 181, 173)
	},
	BlobEmotion.SAD: {
		"left": Rect2(809, 217, 193, 155), # Drooping downward, low pupils
		"right": Rect2(1128, 217, 193, 155)
	},
	BlobEmotion.ANGRY: {
		"left": Rect2(108, 419, 230, 135), # Sharp inner brow angle
		"right": Rect2(393, 419, 230, 135)
	},
	BlobEmotion.SLEEPY: {
		"left": Rect2(809, 398, 194, 157), # Heavy lidded, half closed
		"right": Rect2(1126, 398, 194, 157)
	},
	BlobEmotion.SLEEPING: {
		"left": Rect2(108, 593, 190, 118), # Completely closed flat lines
		"right": Rect2(423, 593, 190, 118)
	},
	BlobEmotion.WINKING: {
		"left": Rect2(808, 591, 191, 114), # Neutral open left eye
		"right": Rect2(1140, 566, 182, 166)      # Closed sleeping right eye
	},
	BlobEmotion.EXCITED: {
		"left": Rect2(117.5, 41, 181.5, 160.4), 
		"right": Rect2(428, 36.5, 182, 168)
	},
	BlobEmotion.SMIRK: {
		"left": Rect2(108, 419, 230, 135), # Sharp inner brow angle
		"right": Rect2(393, 419, 230, 135)
	}
}

# 4. Comprehensive Mapping for all 8 Mouth States
# NOTE: Update these coordinates to match the exact pixel positions in your mouth.png
var mouth_regions: Dictionary = {
	BlobEmotion.IDLE:      Rect2(86.1, 177.2, 182.5, 90.6), # Simple closed gentle smile
	BlobEmotion.HAPPY:     Rect2(401, 142, 252, 145),          # Wide arc smile, open with tongue
	BlobEmotion.SURPRISED: Rect2(811, 122, 140, 194),       # Surprised "O" shape oval
	BlobEmotion.SAD:       Rect2(1145, 177, 168, 70),      # Downward curve frown
	BlobEmotion.ANGRY:     Rect2(50, 472, 261, 191),      # "Grr" clenched teeth rectangle
	BlobEmotion.SLEEPY:    Rect2(429, 561, 207, 49),      # Minimal slight sleeping gap/line
	BlobEmotion.SLEEPING:  Rect2(429, 561, 207, 49),      # Minimal slight sleeping line
	BlobEmotion.EXCITED:  Rect2(754, 451, 255, 253),      # Minimal slight sleeping line
	BlobEmotion.WINKING:   Rect2(86.1, 177.2, 182.5, 90.6),       # Cheeky asymmetric half-smile smirk
	BlobEmotion.SMIRK:   Rect2(1114, 517, 238, 118)       # Cheeky asymmetric half-smile smirk
}

func _ready() -> void:
	# Store the baseline positions for our leg bobbing math
	fl_foot_start_y = front_left_foot.position.y
	fr_foot_start_y = front_right_foot.position.y
	
	# Display initial visual state safely
	_apply_emotion(current_emotion)

func _process(delta: float) -> void:
	time += delta * idle_speed
	
	# Set default modifiers
	var current_amplitude = breath_amplitude
	var current_speed = idle_speed
	
	# Contextual state override: change breathing style when fast asleep
	if current_emotion == BlobEmotion.SLEEPING:
		current_amplitude *= 0.4  # Shallower breaths
		current_speed *= 0.5      # Slower rhythm
		
	# 1. Handle procedural organic stretching (inherited by children automatically)
	var scale_y: float = 1.0 + (sin(time * (current_speed / idle_speed)) * current_amplitude)
	var scale_x: float = 1.0 - (sin(time * (current_speed / idle_speed)) * (current_amplitude * 0.6))
	body.scale = Vector2(scale_x, scale_y)
	
	# 2. Add subtle whole-body float
	body.position.y = sin(time * (current_speed / idle_speed)) * 3.0
	
	# 3. Ground leg shifting rhythm
	front_left_foot.position.y = fl_foot_start_y + (cos(time * (current_speed / idle_speed)) * foot_bob_amplitude)
	front_right_foot.position.y = fr_foot_start_y + (sin(time * (current_speed / idle_speed)) * foot_bob_amplitude)

# Core display engine updating the texture slice regions
func _apply_emotion(emotion: BlobEmotion) -> void:
	if not is_inside_tree(): 
		return
		
	if eye_regions.has(emotion) and left_eye and right_eye:
		left_eye.region_rect = eye_regions[emotion]["left"]
		right_eye.region_rect = eye_regions[emotion]["right"]
		
	if mouth_regions.has(emotion) and mouth:
		mouth.region_rect = mouth_regions[emotion]

# Public API function to update the character expressions dynamically via code
func change_emotion(new_emotion: BlobEmotion) -> void:
	current_emotion = new_emotion
