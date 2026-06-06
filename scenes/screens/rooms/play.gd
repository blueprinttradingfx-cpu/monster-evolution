extends Node2D

# --- Node Map Hooks ---
@onready var blob_creature: Node2D = $BlobCreature
@onready var swing_button: Button = $Interactives/SwingButton
@onready var slide_button: Button = $Interactives/SlideButton

# Reference mapping back to the persistent main system controller
var main_controller: Node = null

func _ready() -> void:
	# Bind interactive park elements
	swing_button.pressed.connect(_on_swing_pressed)
	slide_button.pressed.connect(_on_slide_pressed)

## Called dynamically by main_game_scene.gd right after setup loading
func initialize_room(controller_reference: Node) -> void:
	main_controller = controller_reference
	
	# Check if the blob is too exhausted or hungry to play
	if main_controller and (main_controller.energy <= 20.0 or main_controller.hunger <= 20.0):
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.SAD)
		print("Blob is too tired or hungry to play comfortably.")
	else:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.HAPPY)
		
	print("Play Park Context successfully initialized.")

# --- INTERACTIVE ACTION CALLS ---

func _on_swing_pressed() -> void:
	if not _can_play(): return
	
	# Apply physiological consequences of intense activity
	_apply_play_fatigue(15.0, 10.0) # Drains energy, drops cleanliness
	
	# Trigger a custom high-momentum animation sequence
	# Make the blob perform a wide rhythmic jump to simulate swinging!
	blob_creature.play_jump_action(-180.0, 0.8)
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.6)
	
	# Large coin generation payout for activity completion
	main_controller.add_coins(25)
	print("Blob had fun on the swings! Earned 25 coins.")


func _on_slide_pressed() -> void:
	if not _can_play(): return
	
	_apply_play_fatigue(10.0, 15.0) # Sliding drops cleanliness faster due to dirt ground
	
	# Simulate sliding speed by squashing the face layout and triggering a swift jump
	blob_creature.play_jump_action(-90.0, 0.4)
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.SURPRISED, 0.5)
	
	# Wait for the slide drop, then switch instantly to an excited recovery landing look!
	await get_tree().create_timer(0.45).timeout
	blob_creature.play_jump_action(-40.0, 0.3)
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.2)
	
	main_controller.add_coins(20)
	print("Blob slid down the slide! Earned 20 coins.")

# --- HELPER SYSTEMS ---

## Verifies if the pet is healthy enough to engage in sports mechanics
func _can_play() -> bool:
	if not main_controller: return false
	
	if main_controller.energy <= 15.0:
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.SLEEPY, 1.5)
		print("Play denied: Blob is completely exhausted.")
		return false
		
	if main_controller.hunger <= 15.0:
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.ANGRY, 1.5)
		print("Play denied: Blob is starving.")
		return false
		
	return true

## Updates the persistent core stats on the main framework loop
func _apply_play_fatigue(energy_drain: float, hygiene_drain: float) -> void:
	if not main_controller: return
	main_controller.energy = max(0.0, main_controller.energy - energy_drain)
	main_controller.cleanliness = max(0.0, main_controller.cleanliness - hygiene_drain)