extends Node2D

# --- Node Map Hooks ---
@onready var blob_creature: Node2D = $BlobCreature
@onready var buy_apple_button: Button = $Interactives/BuyAppleButton
@onready var browse_button: Button = $Interactives/BrowseButton

# Reference mapping back to the persistent main system controller
var main_controller: Node = null

func _ready() -> void:
	# Bind interactive merchant buttons
	buy_apple_button.pressed.connect(_on_buy_apple_pressed)
	browse_button.pressed.connect(_on_browse_pressed)

## Called dynamically by main_game_scene.gd right after setup loading
func initialize_room(controller_reference: Node) -> void:
	main_controller = controller_reference
	
	# When entering a shop, the blob is curious and interested!
	blob_creature.change_base_emotion(blob_creature.BlobEmotion.IDLE)
	print("Shop Context successfully initialized.")

# --- INTERACTIVE TRANSACTION ACTIONS ---

func _on_buy_apple_pressed() -> void:
	if not main_controller: return
	
	# Check transaction safety mechanics through the central wallet controller API
	if main_controller.spend_coins(30):
		# Transaction success! Max out hunger with premium food
		main_controller.hunger = min(100.0, main_controller.hunger + 40.0)
		
		# Make the blob jump high and change into an EXCITED expression
		blob_creature.play_jump_action(-150.0, 0.6)
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.EXCITED, 1.8)
		print("Purchased an Apple! Hunger filled. Remaining coins: ", main_controller.total_coins)
	else:
		# Transaction failed due to low budget: Make the blob look disappointed/SAD
		blob_creature.play_action_emotion(blob_creature.BlobEmotion.SAD, 1.4)
		print("Purchase denied: Not enough coins in wallet!")


func _on_browse_pressed() -> void:
	# Window shopping makes the pet curious or sly
	var shop_looks = [blob_creature.BlobEmotion.SURPRISED, blob_creature.BlobEmotion.SMIRK]
	var random_look = shop_looks[randi() % shop_looks.size()]
	
	blob_creature.play_action_emotion(random_look, 1.2)
	blob_creature.play_jump_action(-30.0, 0.3) # Tiny bounce of curiosity
	print("Blob is looking around at shop items...")