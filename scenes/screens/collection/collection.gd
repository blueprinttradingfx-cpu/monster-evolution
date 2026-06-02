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
# const CARD_SCENE = preload("res://scenes/screens/collection/CollectionCard.tscn")
const SYMBOLS: Array = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
const CREATURE_IDS: Array = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]

# ---------------------------------------------------------------------------
# EXPOSED STYLES
# ---------------------------------------------------------------------------
@export var style_card_discovered: StyleBoxFlat
@export var style_card_locked: StyleBoxFlat
@export var style_img_bg: StyleBoxFlat
@export var style_img_locked_bg: StyleBoxFlat
@export var style_tag_bg: StyleBoxFlat

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
	
	# Set all label font sizes to 24px
	completion_pct_label.add_theme_font_size_override("font_size", 24)
	completion_hint.add_theme_font_size_override("font_size", 24)

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
	card.custom_minimum_size = Vector2(200, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_unlocked:
		if style_card_discovered:
			card.add_theme_stylebox_override("panel", style_card_discovered)
	else:
		if style_card_locked:
			card.add_theme_stylebox_override("panel", style_card_locked)
		card.modulate = Color(1, 1, 1, 0.8)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.set("theme_override_constants/separation", 6)
	card.add_child(vbox)

	# Tag Row
	var tag_row: HBoxContainer = HBoxContainer.new()
	tag_row.layout_mode = 2
	vbox.add_child(tag_row)

	var tag_panel: PanelContainer = PanelContainer.new()
	if style_tag_bg:
		tag_panel.add_theme_stylebox_override("panel", style_tag_bg)
	tag_row.add_child(tag_panel)

	var tag_label: Label = Label.new()
	tag_label.text = "MONSTER" if is_unlocked else "???"
	tag_label.add_theme_font_size_override("font_size", 24)
	tag_label.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.286, 0.267, 0.329, 1))
	tag_panel.add_child(tag_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_row.add_child(spacer)

	var num_label: Label = Label.new()
	num_label.text = "#%03d" % index
	num_label.add_theme_font_size_override("font_size", 24)
	num_label.add_theme_color_override("font_color", Color(0.286, 0.267, 0.329, 1))
	tag_row.add_child(num_label)

	# Image Bg
	var img_panel: PanelContainer = PanelContainer.new()
	img_panel.custom_minimum_size.y = 140
	var active_img_style = style_img_bg if is_unlocked else style_img_locked_bg
	if active_img_style:
		img_panel.add_theme_stylebox_override("panel", active_img_style)
	vbox.add_child(img_panel)

	var icon_instance: Control = null
	var creature_data: Resource = null
	if has_node("/root/CreatureRegistry"):
		creature_data = get_node("/root/CreatureRegistry").get_creature(creature_id)

	if creature_data and is_unlocked:
		var icon_scene = load("res://scenes/common/ProceduralCreatureIcon.tscn")
		icon_instance = icon_scene.instantiate()
		icon_instance.setup(creature_data)
		img_panel.add_child(icon_instance)
	else:
		var icon_label: Label = Label.new()
		icon_label.layout_mode = 2

		var is_silhouette = false
		if not is_unlocked and has_node("/root/RetentionSystem"):
			if get_node("/root/RetentionSystem").get_day_number() >= 7:
				is_silhouette = true

		if is_unlocked:
			icon_label.text = _get_icon_for_creature(creature_id)
		elif is_silhouette:
			icon_label.text = _get_icon_for_creature(creature_id)
			icon_label.add_theme_color_override("font_color", Color(0, 0, 0, 1)) # Black silhouette
		else:
			icon_label.text = "❓"

		icon_label.add_theme_font_size_override("font_size", 40)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if not is_unlocked and not is_silhouette:
			icon_label.add_theme_color_override("font_color", Color(0.176, 0.176, 0.176, 0.4))
		img_panel.add_child(icon_label)

	# Name
	var name_label: Label = Label.new()
	name_label.text = MergeSystem.get_creature_name(creature_id).to_upper() if is_unlocked else "LOCKED"
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.286, 0.267, 0.329, 1))
	vbox.add_child(name_label)

	# Stars (Dynamic based on Tier)
	var stars_label: Label = Label.new()
	var tier: int = 1
	if creature_data:
		tier = creature_data.tier

	var stars_text := ""
	for s_idx in range(5):
		if s_idx < tier:
			stars_text += "★"
		else:
			stars_text += "☆"

	stars_label.text = stars_text if is_unlocked else "☆☆☆☆☆"
	stars_label.add_theme_font_size_override("font_size", 24)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_unlocked:
		stars_label.add_theme_color_override("font_color", Color(0.973, 0.741, 0.133, 1))
	else:
		stars_label.add_theme_color_override("font_color", Color(0.851, 0.855, 0.863, 1))
	vbox.add_child(stars_label)

	card.gui_input.connect(_on_card_gui_input.bind(card, creature_id, is_unlocked))

	return card

func _get_icon_for_creature(creature_id: String) -> String:
	if has_node("/root/CreatureRegistry"):
		var data = get_node("/root/CreatureRegistry").get_creature(creature_id)
		if data and data.symbol:
			return data.symbol

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
