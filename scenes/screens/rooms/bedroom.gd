extends Node2D

@onready var blob_creature: Node2D = $BlobCreature
@onready var sleep_button: Button = $Interactives/SleepButton

var main_controller: Node = null
var is_sleeping: bool = false

func _ready() -> void:
	# Sleep button acts as the Bed interaction
	sleep_button.pressed.connect(_on_bed_clicked)
	
	# Touch behavior: Wakes the blob up!
	blob_creature.clicked_on_blob.connect(_on_blob_touched_to_wake)

func initialize_room(controller_reference: Node) -> void:
	main_controller = controller_reference
	if main_controller and main_controller.energy <= 30.0:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.SLEEPY)
	else:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.IDLE)

func is_blob_sleeping() -> bool:
	return is_sleeping

# ACTION 1: Clicking the bed button forces sleep
func _on_bed_clicked() -> void:
	if is_sleeping: return # Already asleep
	
	is_sleeping = true
	sleep_button.text = "Blob is sleeping... (Tap him to wake up)"
	
	blob_creature.change_base_emotion(blob_creature.BlobEmotion.SLEEPING)
	print("Bed clicked: Blob went to sleep.")

# ACTION 2: Direct touch wakes the blob up!
func _on_blob_touched_to_wake() -> void:
	if not is_sleeping:
		# If already awake, tapping just makes it yawn/wink playfully
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.WINKING, 1.0)
		return
		
	# Wake up procedure
	is_sleeping = false
	sleep_button.text = "Go to Bed 💤"
	
	# Celebrate waking up
	if main_controller and main_controller.energy >= 99.0:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.HAPPY)
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.5)
		blob_creature.play_jump_action(-100.0, 0.5)
		main_controller.add_coins(20)
	else:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.IDLE)
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.SURPRISED, 1.0)
		
	print("Blob was touched: Woke up!")
