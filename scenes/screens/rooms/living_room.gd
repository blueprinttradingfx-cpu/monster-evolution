extends Node2D

@onready var blob_creature: Node2D = $BlobCreature
@onready var couch_button: Button = $Interactives/CouchButton

var main_controller: Node = null

func _ready() -> void:
	couch_button.pressed.connect(_on_couch_clicked)
	
	# Listen for when the player touches the blob directly!
	blob_creature.clicked_on_blob.connect(_on_blob_touched_to_eat)

func initialize_room(controller_reference: Node) -> void:
	main_controller = controller_reference
	blob_creature.change_base_emotion(blob_creature.BlobEmotion.IDLE)

# ACTION 1: Direct touch makes it eat a snack!
func _on_blob_touched_to_eat() -> void:
	if not main_controller: return
	
	# Deduct coins and feed
	if main_controller.spend_coins(10): 
		main_controller.hunger = min(100.0, main_controller.hunger + 25.0) 
		
		# Play eating/excited animations
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.2) 
		blob_creature.play_jump_action(-80.0, 0.4) 
		print("Touched blob: Munch munch! Blob ate a snack.")
	else:
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.ANGRY, 1.0) 
		print("Touched blob: Tried to feed, but no coins!")

# ACTION 2: Clicking the couch button makes it sit
func _on_couch_clicked() -> void:
	blob_creature.play_jump_action(-120.0, 0.6) 
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.HAPPY, 2.0) 
	
	if main_controller:
		main_controller.energy = min(100.0, main_controller.energy + 5.0) 
