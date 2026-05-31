extends Control
## creature-detail.gd
## Controller for creature-detail.tscn
## Uses common TopAppBar and BottomNav, GameState for navigation, MergeSystem for creature data

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------
const SYMBOLS: Array = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
const CREATURE_IDS: Array = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
const RARITIES: Array = ["Common", "Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Dictionary = {
	"Common": Color(0.4, 0.4, 0.4, 1),
	"Uncommon": Color(0.204, 0.827, 0.6, 1),
	"Rare": Color(0.584, 0.431, 0, 1),
	"Epic": Color(0.518, 0.208, 0.831, 1),
	"Legendary": Color(0.937, 0.455, 0.067, 1),
}
const DESCRIPTIONS: Dictionary = {
	"egg": "The start of your adventure!",
	"baby_dino": "A cute, curious baby dinosaur.",
	"raptor": "Fast and clever, loves to run.",
	"t_rex": "A mighty king of the dinosaurs!",
	"dragon": "Breathes fire and soars high.",
	"lava_dragon": "A powerful lava-dwelling beast."
}

# ---------------------------------------------------------------------------
# NODE REFS
# ---------------------------------------------------------------------------
@onready var back_button: Button = $BackButton
@onready var top_appbar: TopAppBar = $TopAppBar
@onready var monster_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer/MonsterImage
@onready var monster_emoji: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer/MonsterEmoji
@onready var rarity_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill/RarityLabel
@onready var rarity_pill: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill
@onready var monster_name: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/MonsterNameCenter/MonsterName
@onready var evo_stage_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/EvoPillCenter/EvoPill/EvoPillHBox/EvoStageLabel
@onready var attack_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/AttackCard/AttackVBox/AttackValue
@onready var energy_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/EnergyCard/EnergyVBox/EnergyValue
@onready var about_body: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/AboutSection/AboutVBox/AboutBody
@onready var ingredient1_emoji: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Bubble/Ingredient1Emoji
@onready var ingredient1_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Bubble/Ingredient1Image
@onready var ingredient1_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Label
@onready var ingredient2_emoji: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Bubble/Ingredient2Emoji
@onready var ingredient2_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Bubble/Ingredient2Image
@onready var ingredient2_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Label
@onready var result_emoji_node: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultBubble/ResultEmoji
@onready var result_image_node: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultBubble/ResultImage
@onready var result_label_node: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultLabel
@onready var cta_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/CtaButton
@onready var sparkle_layer: Control = $SparkleLayer
@onready var bottom_nav: BottomNav = $BottomNav

# ---------------------------------------------------------------------------
# PRIVATE STATE
# ---------------------------------------------------------------------------
var _creature_id: String = ""
var _float_tween: Tween = null
var _float_base_y: float = 0.0
var _cta_base_y: float = 0.0

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Get creature_id from GameState
	_creature_id = GameState.current_creature_id
	
	# Populate UI
	_populate_ui()
	
	# Animate
	_play_bounce_in()
	_start_float_animation()
	
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	cta_button.pressed.connect(_on_cta_pressed)
	cta_button.button_down.connect(_on_cta_down)
	cta_button.button_up.connect(_on_cta_up)
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	
	# Setup BottomNav
	bottom_nav.set_active("collection")
	bottom_nav.start_button.visible = false

# ---------------------------------------------------------------------------
# UI POPULATION
# ---------------------------------------------------------------------------
func _populate_ui() -> void:
	if _creature_id == "":
		return
	
	_populate_header()
	_populate_hero()
	_populate_stats()
	_populate_about()
	_populate_evolution()
	_populate_cta()

func _populate_header() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)

func _populate_hero() -> void:
	var idx: int = CREATURE_IDS.find(_creature_id)
	if idx == -1:
		idx = 0
	
	monster_name.text = MergeSystem.get_creature_name(_creature_id)
	
	var tier: int = MergeSystem.get_evolution_level(_creature_id)
	evo_stage_label.text = "Evolution Stage: %d" % tier
	
	var rarity: String = RARITIES[idx]
	rarity_label.text = rarity.to_upper()
	
	if RARITY_COLORS.has(rarity):
		# For now we can just set modulate, or use theme override
		rarity_pill.modulate = RARITY_COLORS[rarity]
	
	# For now just use emoji
	monster_emoji.text = SYMBOLS[idx]
	monster_emoji.visible = true
	monster_image.visible = false

func _populate_stats() -> void:
	var idx: int = CREATURE_IDS.find(_creature_id)
	if idx == -1:
		idx = 0
	
	# Simple attack and energy based on tier
	var tier: int = MergeSystem.get_evolution_level(_creature_id)
	attack_value.text = str(tier * 42)
	energy_value.text = str(tier * 31)

func _populate_about() -> void:
	about_body.text = DESCRIPTIONS.get(_creature_id, "A mysterious creature!")

func _populate_evolution() -> void:
	var idx: int = CREATURE_IDS.find(_creature_id)
	if idx == -1:
		idx = 0
	
	# Find previous creature (the ingredient)
	if idx > 0:
		var prev_id: String = CREATURE_IDS[idx - 1]
		ingredient1_label.text = MergeSystem.get_creature_name(prev_id)
		ingredient1_emoji.text = SYMBOLS[idx - 1]
		ingredient1_emoji.visible = true
		ingredient1_image.visible = false
		
		ingredient2_label.text = MergeSystem.get_creature_name(prev_id)
		ingredient2_emoji.text = SYMBOLS[idx - 1]
		ingredient2_emoji.visible = true
		ingredient2_image.visible = false
	else:
		ingredient1_label.text = "Egg"
		ingredient1_emoji.text = "🥚"
		ingredient2_label.text = "Egg"
		ingredient2_emoji.text = "🥚"
	
	result_label_node.text = MergeSystem.get_creature_name(_creature_id)
	result_emoji_node.text = SYMBOLS[idx]
	result_emoji_node.visible = true
	result_image_node.visible = false

func _populate_cta() -> void:
	cta_button.text = "🪄  Merge More!"

# ---------------------------------------------------------------------------
# ANIMATIONS
# ---------------------------------------------------------------------------
func _play_bounce_in() -> void:
	var hero_section: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection
	if hero_section:
		hero_section.scale = Vector2(0.9, 0.9)
		hero_section.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(hero_section, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(hero_section, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _start_float_animation() -> void:
	var image_container: CenterContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer
	if image_container:
		_float_base_y = image_container.position.y
		if _float_tween:
			_float_tween.kill()
		_float_tween = create_tween()
		_float_tween.set_loops()
		_float_tween.tween_property(
			image_container, "position:y",
			_float_base_y - 10.0,
			1.5
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_float_tween.tween_property(
			image_container, "position:y",
			_float_base_y,
			1.5
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _burst_sparkles(origin: Vector2) -> void:
	var sparkle_chars = ["✨", "⭐", "💫", "🌟"]
	var sparkle_colors = [
		Color(0.518, 0.208, 0.831, 1),
		Color(0.992, 0.878, 0.133, 1),
		Color(0.204, 0.827, 0.6, 1),
		Color(0.925, 0.286, 0.6, 1),
	]

	for i in range(8):
		var lbl = Label.new()
		lbl.text = sparkle_chars[i % sparkle_chars.size()]
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", sparkle_colors[i % sparkle_colors.size()])
		lbl.position = origin
		lbl.mouse_filter = 2
		sparkle_layer.add_child(lbl)

		var angle = (float(i) / 8.0) * TAU
		var dist = 90.0 + randf() * 40.0
		var target = origin + Vector2(cos(angle), sin(angle)) * dist

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(lbl, "position", target, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(lbl, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		tween.tween_property(lbl, "scale", Vector2(0.2, 0.2), 0.6).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(lbl.queue_free)

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.COLLECTION)

func _on_cta_down() -> void:
	_cta_base_y = cta_button.position.y
	var tween = create_tween()
	tween.tween_property(cta_button, "position:y", _cta_base_y + 4.0, 0.06)

func _on_cta_up() -> void:
	var tween = create_tween()
	tween.tween_property(cta_button, "position:y", _cta_base_y, 0.08)

func _on_cta_pressed() -> void:
	GameState.go_to(GameState.Screen.MERGE)

func _on_tab_pressed(tab_name: String) -> void:
	bottom_nav.set_active(tab_name)
	match tab_name:
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
