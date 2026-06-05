extends Control

# Shop Screen - Tabs for Eggs and Cosmetics
# This screen renders the catalog and delegates purchases to MonsterManager.

# --- NODES ---
@onready var _safe_area: MarginContainer = $RootLayout/ScrollContainer/SafeArea
@onready var _top_app_bar: Control = $RootLayout/TopAppBar
@onready var _bottom_nav: BottomNav = $RootLayout/BottomNav
@onready var _tab_container: TabContainer = $RootLayout/ScrollContainer/SafeArea/MainContent/TabContainer
@onready var _eggs_list: VBoxContainer = $RootLayout/ScrollContainer/SafeArea/MainContent/TabContainer/EggsTab/ScrollContainer/Content
@onready var _cosmetics_list: VBoxContainer = $RootLayout/ScrollContainer/SafeArea/MainContent/TabContainer/CosmeticsTab/ScrollContainer/Content

# --- VARIABLES ---
var _egg_types: Array[EggType] = []
var _cosmetics: Array[Cosmetic] = []
var _egg_buttons: Dictionary = {}  # egg_type_id -> Button
var _cosmetic_buttons: Dictionary = {}  # cosmetic_id -> Button

# --- INITIALIZATION ---
func _ready() -> void:
	_apply_safe_area()
	_load_egg_types()
	_load_cosmetics()
	_populate_eggs_tab()
	_populate_cosmetics_tab()
	if _bottom_nav and _bottom_nav.has_method("set_active"):
		_bottom_nav.set_active("Shop")
	if _bottom_nav and _bottom_nav.has_method("tab_changed"):
		_bottom_nav.tab_changed.connect(_on_tab_pressed)
	if EconomyManager:
		EconomyManager.coins_changed.connect(_on_coins_changed)
	_update_all_button_states()

func _apply_safe_area() -> void:
	var safe_area_rect: Rect2i = DisplayServer.get_display_safe_area()
	_safe_area.add_theme_constant_override("margin_top", safe_area_rect.position.y)
	_safe_area.add_theme_constant_override("margin_bottom", DisplayServer.window_get_size().y - safe_area_rect.end.y)

func _on_tab_pressed(tab: String) -> void:
	if _bottom_nav and _bottom_nav.has_method("set_active"):
		_bottom_nav.set_active(tab)
	match tab:
		"Home":
			if GameState:
				GameState.go_to(GameState.Screen.MENU)
		"Collection":
			if GameState:
				GameState.go_to(GameState.Screen.COLLECTION)
		"Shop":
			pass

func _on_coins_changed(new_coins: int) -> void:
	_update_all_button_states()

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
	_egg_buttons[egg_type.id] = buy_button
	
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
	_cosmetic_buttons[cosmetic.id] = buy_button
	
	_cosmetics_list.add_child(card)

func _update_all_button_states() -> void:
	var current_coins: int = EconomyManager.get_coins() if EconomyManager else 0
	
	# Update egg buttons
	for egg_type in _egg_types:
		var button: Button = _egg_buttons.get(egg_type.id)
		if button:
			button.disabled = current_coins < egg_type.price
	
	# Update cosmetic buttons
	for cosmetic in _cosmetics:
		var button: Button = _cosmetic_buttons.get(cosmetic.id)
		if button:
			var is_owned: bool = MonsterManager.owned_cosmetic_ids.has(cosmetic.id) if MonsterManager else false
			button.disabled = is_owned or (current_coins < cosmetic.price)
			button.text = "Owned" if is_owned else "Buy"

func _on_buy_egg_pressed(egg_type_id: String) -> void:
	if MonsterManager:
		var success: bool = MonsterManager.buy_egg(egg_type_id)
		if success:
			_update_all_button_states()
			if _top_app_bar and _top_app_bar.has_method("set_eggs"):
				_top_app_bar.set_eggs(MonsterManager.get_owned_egg_count())
		else:
			push_warning("Shop: failed to purchase egg %s" % egg_type_id)

func _on_buy_cosmetic_pressed(cosmetic_id: String) -> void:
	if MonsterManager:
		var success: bool = MonsterManager.buy_cosmetic(cosmetic_id)
		if success:
			_update_all_button_states()
		else:
			push_warning("Shop: failed to purchase cosmetic %s" % cosmetic_id)
