extends Control
## CollectionScreen.gd
## Controller for collection_screen.tscn
## Uses MergeSystem for creature data, GameState for navigation, common Top/BottomNav

# ---------------------------------------------------------------------------
# NODE REFS
# ---------------------------------------------------------------------------
@onready var top_appbar: TopAppBar = $TopAppBar
@onready var completion_pct_label: Label = $MainLayout/ScrollContainer/ContentVBox/SidePadding/InnerContent/TitleSection/CompletionPanel/CompletionVBox/CompletionRow/CompletionPct
@onready var progress_fill: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SidePadding/InnerContent/TitleSection/CompletionPanel/CompletionVBox/ProgressBarBg/ProgressFill
@onready var completion_hint: Label = $MainLayout/ScrollContainer/ContentVBox/SidePadding/InnerContent/TitleSection/CompletionPanel/CompletionVBox/CompletionHint
@onready var card_grid: GridContainer = $MainLayout/ScrollContainer/ContentVBox/SidePadding/InnerContent/CardGrid
@onready var bottom_nav: BottomNav = $BottomNav

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------
const SYMBOLS: Array = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
const CREATURE_IDS: Array = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]

# ---------------------------------------------------------------------------
# PRIVATE STATE
# ---------------------------------------------------------------------------
var _tween: Tween = null

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------
func _ready() -> void:
	_refresh_currency_display()
	_populate_collection()
	_animate_progress_bar()
	
	# Connect signals
	MergeSystem.creature_unlocked.connect(_populate_collection)
	MergeSystem.inventory_updated.connect(_populate_collection)
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	
	bottom_nav.set_active("collection")
	bottom_nav.start_button.visible = false

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
func _refresh_currency_display() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)

# ---------------------------------------------------------------------------
# PROGRESS BAR
# ---------------------------------------------------------------------------
func _animate_progress_bar() -> void:
	var all_creature_ids: Array = MergeSystem.get_all_creature_ids()
	var unlocked_count: int = 0
	for creature_id in all_creature_ids:
		if MergeSystem.is_unlocked(creature_id):
			unlocked_count += 1
	
	var ratio: float = float(unlocked_count) / float(max(all_creature_ids.size(), 1))
	var pct_int: int = int(round(ratio * 100.0))
	completion_pct_label.text = "%d%%" % pct_int
	_update_hint_text(unlocked_count, all_creature_ids.size())

	progress_fill.anchor_right = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(progress_fill, "anchor_right", ratio, 0.8)

func _update_hint_text(unlocked: int, total: int) -> void:
	var remaining := total - unlocked
	if remaining <= 0:
		completion_hint.text = "🎉 Collection complete!"
	else:
		completion_hint.text = (
			"Find %d more monster%s to unlock them all!"
			% [remaining, ("s" if remaining != 1 else "")]
		)

# ---------------------------------------------------------------------------
# CARD POPULATION
# ---------------------------------------------------------------------------
func _populate_collection() -> void:
	var all_creature_ids: Array = MergeSystem.get_all_creature_ids()
	
	# Clear old cards
	for child in card_grid.get_children():
		child.queue_free()
	
	# Add new cards
	for i in range(all_creature_ids.size()):
		var creature_id: String = all_creature_ids[i]
		var is_unlocked: bool = MergeSystem.is_unlocked(creature_id)
		var creature_card: PanelContainer = _create_creature_card(creature_id, is_unlocked, i + 1)
		card_grid.add_child(creature_card)
	
	_animate_progress_bar()
	_refresh_currency_display()

func _create_creature_card(creature_id: String, is_unlocked: bool, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 200)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.layout_mode = 2
	card.add_child(vbox)
	
	# Add icon
	var icon_label: Label = Label.new()
	icon_label.custom_minimum_size.y = 120
	icon_label.layout_mode = 2
	if is_unlocked:
		icon_label.text = _get_icon_for_creature(creature_id)
	else:
		icon_label.text = "❓"
	icon_label.add_theme_font_size_override("font_size", 64)
	icon_label.horizontal_alignment = 1
	vbox.add_child(icon_label)
	
	# Add name
	var name_label: Label = Label.new()
	name_label.layout_mode = 2
	if is_unlocked:
		name_label.text = MergeSystem.get_creature_name(creature_id)
	else:
		name_label.text = "LOCKED"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = 1
	vbox.add_child(name_label)
	
	# Dim locked cards
	if not is_unlocked:
		card.modulate = Color(1, 1, 1, 0.8)
	
	card.gui_input.connect(_on_card_gui_input.bind(card, creature_id, is_unlocked))
	
	return card

func _get_icon_for_creature(creature_id: String) -> String:
	var idx: int = CREATURE_IDS.find(creature_id)
	if idx != -1:
		return SYMBOLS[idx]
	return "?"

# ---------------------------------------------------------------------------
# INPUT — CARDS
# ---------------------------------------------------------------------------
func _on_card_gui_input(event: InputEvent, card: Control, creature_id: String, is_unlocked: bool) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_card(card)
			else:
				_release_card(card)
				if is_unlocked:
					_show_monster_detail(creature_id)
				else:
					_show_locked_toast()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_card(card)
		else:
			_release_card(card)
			if is_unlocked:
				_show_monster_detail(creature_id)
			else:
				_show_locked_toast()

func _press_card(card: Control) -> void:
	var tween := create_tween()
	tween.tween_property(card, "position:y", card.position.y + 4.0, 0.06)

func _release_card(card: Control) -> void:
	var tween := create_tween()
	tween.tween_property(card, "position:y", card.position.y - 4.0, 0.08)

# ---------------------------------------------------------------------------
# DETAIL / TOAST
# ---------------------------------------------------------------------------
func _show_monster_detail(creature_id: String) -> void:
	GameState.go_to(GameState.Screen.CREATURE_DETAIL, {"creature_id": creature_id})

func _show_locked_toast() -> void:
	print("[CollectionScreen] Monster is locked.")

# ---------------------------------------------------------------------------
# INPUT — NAVIGATION
# ---------------------------------------------------------------------------
func _on_tab_pressed(tab: String) -> void:
	bottom_nav.set_active(tab)
	match tab:
		"play":
			GameState.go_to(GameState.Screen.MENU)
		"merge":
			GameState.go_to(GameState.Screen.MERGE)
		"collection":
			GameState.go_to(GameState.Screen.COLLECTION)
		"shop":
			GameState.go_to(GameState.Screen.SHOP)
		"settings":
			GameState.go_to(GameState.Screen.SETTINGS)
