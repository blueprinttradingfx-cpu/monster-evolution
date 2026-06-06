extends Control

# --- Node Reference Safe Map ---
@onready var coin_label: Label = $CanvasLayer/UIControl/Header/MarginContainer/HeaderLayout/CoinLabel
@onready var status_label: Label = $CanvasLayer/UIControl/Header/MarginContainer/HeaderLayout/StatusLabel
@onready var drawer_content: VBoxContainer = $CanvasLayer/UIControl/FloatingDrawer/DrawerContent
@onready var room_container: Node2D = $RoomContainer

# --- Room Path Mapping CONFIGURATION ---
# Note: Ensure these file paths match where you save your room sub-scenes
const ROOMS = {
	"living_room": "res://scenes/screens/rooms/living_room.tscn",
	"bathroom": "res://scenes/screens/rooms/bathroom.tscn",
	"bedroom": "res://scenes/screens/rooms/bedroom.tscn",
	"play": "res://scenes/screens/rooms/play.tscn",
	"shop": "res://scenes/screens/rooms/shop.tscn"
}

# --- Core Virtual Pet Metrics ---
var total_coins: int = 120:
	set(value):
		total_coins = value
		_update_ui()

var hunger: float = 100.0
var energy: float = 100.0
var cleanliness: float = 100.0

var current_room_key: String = ""
var current_room_node: Node = null
var is_drawer_open: bool = false
var drawer_base_y: float = 0.0

func _ready() -> void:
	_update_ui()
	
	# Cache floating drawer positions for relative linear interpolation targets
	drawer_base_y = drawer_content.position.y
	drawer_content.visible = false
	drawer_content.modulate.a = 0.0
	
	# Load baseline living room context on system start
	change_room("living_room")
	
	# Establish layout action signal listeners
	_wire_ui_signals()

func _process(delta: float) -> void:
	_process_pet_stats(delta)

# --- STATS ENGINE ---
func _process_pet_stats(delta: float) -> void:
	# Deplete metrics over time (adjust multipliers to speed up/slow down)
	hunger = max(0.0, hunger - (delta * 0.4))
	cleanliness = max(0.0, cleanliness - (delta * 0.3))
	
	# Energy depletes normally EXCEPT when the pet is asleep in the bedroom
	if current_room_key == "bedroom" and is_instance_valid(current_room_node) and current_room_node.has_method("is_blob_sleeping") and current_room_node.is_blob_sleeping():
		energy = min(100.0, energy + (delta * 4.0)) # Recharge quickly during sleep
	else:
		energy = max(0.0, energy - (delta * 0.2))

	_evaluate_stat_warnings()

func _evaluate_stat_warnings() -> void:
	# Context-driven auto-navigation triggers or alerts based on critical metrics
	if energy <= 10.0 and current_room_key != "bedroom":
		status_label.text = "Status: Exhausted! Going to bed..."
		change_room("bedroom")
	elif hunger <= 25.0:
		status_label.text = "Status: Hungry! Needs Food"
	elif cleanliness <= 25.0:
		status_label.text = "Status: Dirty! Needs a Bath"
	else:
		if current_room_key == "bedroom" and energy >= 99.0:
			status_label.text = "Status: Fully Rested!"
		else:
			status_label.text = "Status: Stable"

func _update_ui() -> void:
	if coin_label:
		coin_label.text = str(total_coins)

func _wire_ui_signals() -> void:
	# Bind primary footer route changes
	$CanvasLayer/UIControl/Footer/MarginContainer/FooterLayout/LivingRoomButton.pressed.connect(func(): change_room("living_room"))
	$CanvasLayer/UIControl/Footer/MarginContainer/FooterLayout/BathroomButton.pressed.connect(func(): change_room("bathroom"))
	$CanvasLayer/UIControl/Footer/MarginContainer/FooterLayout/BedroomButton.pressed.connect(func(): change_room("bedroom"))
	$CanvasLayer/UIControl/Footer/MarginContainer/FooterLayout/PlayButton.pressed.connect(func(): change_room("play"))
	$CanvasLayer/UIControl/Footer/MarginContainer/FooterLayout/ShopButton.pressed.connect(func(): change_room("shop"))
	
	# Bind contextual floating nav drawer drawer actions
	$CanvasLayer/UIControl/FloatingDrawer/ToggleDrawerButton.pressed.connect(toggle_drawer)
	$CanvasLayer/UIControl/FloatingDrawer/DrawerContent/SettingsButton.pressed.connect(_on_settings_selected)
	$CanvasLayer/UIControl/FloatingDrawer/DrawerContent/Nav1Button.pressed.connect(_on_inventory_selected)
	$CanvasLayer/UIControl/FloatingDrawer/DrawerContent/Nav2Button.pressed.connect(_on_stats_selected)

# --- DYNAMIC ROUTING ENGINE ---
func change_room(room_key: String) -> void:
	if current_room_key == room_key:
		return # Avoid duplicate scene loads
		
	if not ROOMS.has(room_key):
		push_error("Target key invalid: " + room_key)
		return
		
	# 1. Clean up old room node safely
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
	
	# 2. Check if file path target resource exists before loading
	var path = ROOMS[room_key]
	if not ResourceLoader.exists(path):
		print("Placeholder Node active: Create '" + path + "' to map full room elements.")
		current_room_node = Node2D.new()
		current_room_node.name = room_key.capitalize() + "Placeholder"
		room_container.add_child(current_room_node)
		current_room_key = room_key
		return
		
	# 3. Instantiate and attach verified room node structures
	var room_resource = load(path)
	current_room_node = room_resource.instantiate()
	room_container.add_child(current_room_node)
	current_room_key = room_key
	
	# 4. Inject main controller dependency into the new room scene context
	if current_room_node.has_method("initialize_room"):
		current_room_node.initialize_room(self)

# --- FLOATING NAV DRAWER ANIMATION ---
func toggle_drawer() -> void:
	is_drawer_open = !is_drawer_open
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_drawer_open:
		drawer_content.visible = true
		# Slide up smoothly from current height and fade in opacity
		tween.tween_property(drawer_content, "modulate:a", 1.0, 0.22)
		tween.tween_property(drawer_content, "position:y", drawer_base_y - 30.0, 0.22)
	else:
		# Drop down and fade out smoothly
		tween.tween_property(drawer_content, "modulate:a", 0.0, 0.18)
		tween.tween_property(drawer_content, "position:y", drawer_base_y, 0.18)
		tween.chain().tween_callback(func(): drawer_content.visible = false)

# --- DATA MUTATOR INTERFACES ---
func add_coins(amount: int) -> void:
	total_coins += amount

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		return true
	return false

# --- CONTEXT FLOATING ACTIONS ---
func _on_settings_selected() -> void:
	print("UI Event: Settings Overlay Activated")
	toggle_drawer()

func _on_inventory_selected() -> void:
	print("UI Event: Inventory Grid Activated")
	toggle_drawer()

func _on_stats_selected() -> void:
	print("UI Event: Detail Stats Sub-Display Activated")
	print("Hunger: %d, Energy: %d, Cleanliness: %d" % [hunger, energy, cleanliness])
	toggle_drawer()
