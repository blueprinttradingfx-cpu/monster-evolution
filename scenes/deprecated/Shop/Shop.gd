extends Control

# Shop Screen - Tabs for Eggs and Cosmetics
# Per TICKET-22, TICKET-23, TICKET-24 and AGENTS.md (no game logic in UI)

# --- SIGNALS ---
signal item_purchased(item_id: String, item_type: String)
signal buy_egg(egg_type_id: String)
signal buy_cosmetic(cosmetic_id: String)

# --- NODES ---
@onready var _top_app_bar: Control = $TopAppBar
@onready var _bottom_nav: Control = $BottomNav
@onready var _tab_container: TabContainer = $MainContent/TabContainer
@onready var _eggs_list: VBoxContainer = $MainContent/TabContainer/EggsTab/ScrollContainer/Content
@onready var _cosmetics_list: VBoxContainer = $MainContent/TabContainer/CosmeticsTab/ScrollContainer/Content

# --- VARIABLES ---
var _egg_types: Array[EggType] = []
var _cosmetics: Array[Cosmetic] = []

# --- INITIALIZATION ---
func _ready() -> void:
	_load_egg_types()
	_load_cosmetics()
	_populate_eggs_tab()
	_populate_cosmetics_tab()

func _on_buy_egg_pressed(egg_type_id: String) -> void:
	if MonsterManager:
		var success: bool = MonsterManager.buy_egg(egg_type_id)
		if success:
			print("Egg purchased: ", egg_type_id)

func _on_buy_cosmetic_pressed(cosmetic_id: String) -> void:
	if MonsterManager:
		var success: bool = MonsterManager.buy_cosmetic(cosmetic_id)
		if success:
			print("Cosmetic purchased: ", cosmetic_id)

func _load_egg_types() -> void:
	# Load EggType resources from data/eggs/
	var dino_egg: Resource = load("res://data/eggs/dino_egg.tres")
	if dino_egg and dino_egg is EggType:
		_egg_types.append(dino_egg)
	
	var slime_egg: Resource = load("res://data/eggs/slime_egg.tres")
	if slime_egg and slime_egg is EggType:
		_egg_types.append(slime_egg)

func _load_cosmetics() -> void:
	# Load Cosmetic resources from data/cosmetics/
	var cosmetic_files := [
		"res://data/cosmetics/knight_helmet.tres",
		"res://data/cosmetics/knight_armor.tres",
		"res://data/cosmetics/knight_cape.tres",
		"res://data/cosmetics/pirate_hat.tres",
		"res://data/cosmetics/eye_patch.tres",
		"res://data/cosmetics/pirate_coat.tres",
		"res://data/cosmetics/wizard_hat.tres",
		"res://data/cosmetics/wizard_robe.tres",
		"res://data/cosmetics/ninja_headband.tres",
		"res://data/cosmetics/ninja_mask.tres",
		"res://data/cosmetics/chef_hat.tres",
		"res://data/cosmetics/chef_apron.tres",
		"res://data/cosmetics/alien_antenna.tres",
		"res://data/cosmetics/alien_space_suit.tres"
	]
	
	for file_path in cosmetic_files:
		var cosmetic_resource := load(file_path)
		if cosmetic_resource and cosmetic_resource is Cosmetic:
			_cosmetics.append(cosmetic_resource)

func _populate_eggs_tab() -> void:
	for egg_type in _egg_types:
		_add_egg_card(egg_type)

func _populate_cosmetics_tab() -> void:
	for cosmetic in _cosmetics:
		_add_cosmetic_card(cosmetic)

func _add_egg_card(egg_type: EggType) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 150)
	var vbox: VBoxContainer = VBoxContainer.new()
	card.add_child(vbox)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = egg_type.name
	name_label.theme_type_variation = "HeaderMedium"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Price
	var price_label: Label = Label.new()
	price_label.text = "%d Coins" % egg_type.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)
	
	# Buy button
	var buy_button: Button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(200, 50)
	buy_button.pressed.connect(func(): _on_buy_egg_pressed(egg_type.id))
	vbox.add_child(buy_button)
	
	_eggs_list.add_child(card)

func _add_cosmetic_card(cosmetic: Cosmetic) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 150)
	var vbox: VBoxContainer = VBoxContainer.new()
	card.add_child(vbox)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = cosmetic.name
	name_label.theme_type_variation = "HeaderMedium"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Slot
	var slot_label: Label = Label.new()
	slot_label.text = "Slot: %s" % cosmetic.slot
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_label)
	
	# Price
	var price_label: Label = Label.new()
	price_label.text = "%d Coins" % cosmetic.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)
	
	# Buy button
	var buy_button: Button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(200, 50)
	buy_button.pressed.connect(func(): _on_buy_cosmetic_pressed(cosmetic.id))
	vbox.add_child(buy_button)
	
	_cosmetics_list.add_child(card)


