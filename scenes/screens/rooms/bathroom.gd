extends Node2D

@onready var blob_creature: Node2D = $BlobCreature
@onready var toilet_button: Button = $Interactives/ToiletButton

var main_controller: Node = null

func _ready() -> void:
	toilet_button.pressed.connect(_on_toilet_clicked)
	
	# Touch behavior: Instantly starts cleaning the pet!
	blob_creature.clicked_on_blob.connect(_on_blob_touched_to_wash)

func initialize_room(controller_reference: Node) -> void:
	main_controller = controller_reference
	if main_controller and main_controller.cleanliness <= 30.0:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.SAD)
	else:
		blob_creature.change_base_emotion(blob_creature.BlobEmotion.IDLE)

func _on_blob_touched_to_wash() -> void:
	if not main_controller: return
	
	if main_controller.cleanliness >= 95.0:
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.SMIRK, 1.0)
		return
		
	main_controller.cleanliness = 100.0
	blob_creature.change_base_emotion(blob_creature.BlobEmotion.HAPPY)
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.4)
	blob_creature.play_jump_action(-120.0, 0.5)
	main_controller.add_coins(15)

func _on_toilet_clicked() -> void:
	blob_creature.play_jump_action(-80.0, 0.4)
	blob_creature.play_action_emotion(blob_creature.BlobEmotion.SURPRISED, 1.0)
	if main_controller:
		main_controller.add_coins(5)