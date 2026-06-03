extends Control
## creature-detail.gd
## Controller for creature-detail.tscn
## Uses common TopAppBar and BottomNav, GameManager for navigation, MonsterManager for data

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------
const STAGE_NAMES: Array = ["Egg", "Baby", "Kid", "Adult", "Elder"]
const DESCRIPTIONS: Dictionary = {
	"dino": "A mighty dinosaur companion!",
	"slime": "A cute and squishy slime friend!"
}

# ---------------------------------------------------------------------------
# NODE REFS
# ---------------------------------------------------------------------------
@onready var back_button: Button = $BackButton
@onready var top_appbar: Control = $TopAppBar
@onready var monster_display: Control = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer/MonsterDisplay
@onready var rarity_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill/RarityLabel
@onready var rarity_pill: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill
@onready var monster_name: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/MonsterNameCenter/MonsterName
@onready var evo_stage_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/EvoPillCenter/EvoPill/EvoPillHBox/EvoStageLabel
@onready var attack_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/AttackCard/AttackVBox/AttackValue
@onready var energy_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/EnergyCard/EnergyVBox/EnergyValue
@onready var about_body: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/AboutSection/AboutVBox/AboutBody
@onready var cta_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/CtaButton
@onready var sparkle_layer: Control = $SparkleLayer
@onready var bottom_nav: Control = $BottomNav

# ---------------------------------------------------------------------------
# PRIVATE STATE
# ---------------------------------------------------------------------------
var _monster_id: String = ""
var _float_tween: Tween = null
var _float_base_y: float = 0.0
var _cta_base_y: float = 0.0

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Get monster_id from GameState
	_monster_id = GameState.current_creature_id
	
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
	bottom_nav.set_active("Collection")
	
	# Set all label font sizes to 24px
	rarity_label.add_theme_font_size_override("font_size", 24)
	monster_name.add_theme_font_size_override("font_size", 24)
	evo_stage_label.add_theme_font_size_override("font_size", 24)
	attack_value.add_theme_font_size_override("font_size", 24)
	energy_value.add_theme_font_size_override("font_size", 24)
	about_body.add_theme_font_size_override("font_size", 24)
	
	# Set all button font sizes to 24px
	back_button.add_theme_font_size_override("font_size", 24)
	cta_button.add_theme_font_size_override("font_size", 24)

# ---------------------------------------------------------------------------
# UI POPULATION
# ---------------------------------------------------------------------------
func _populate_ui() -> void:
	if _monster_id == "":
		return
	
	_populate_header()
	_populate_hero()
	_populate_stats()
	_populate_about()
	_populate_cta()

func _populate_header() -> void:
	if top_appbar:
		if EconomyManager:
			top_appbar.set_coins(EconomyManager.get_coins())

func _populate_hero() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var species_id: String = monster_data.get("speciesId", "dino")
	var stage_id: String = monster_data.get("stageId", "stage_1")
	var stage_num: int = _get_stage_number(stage_id)
	
	# Update monster display
	if monster_display:
		monster_display.set_monster(monster_data)
	
	# Update monster name
	var species_path: String = "res://data/species/%s.tres" % species_id
	var species: Resource = load(species_path)
	if species:
		monster_name.text = species.name
	else:
		monster_name.text = species_id.capitalize()
	
	# Update evolution stage
	evo_stage_label.text = "Stage: %s" % STAGE_NAMES[stage_num]
	
	# Update rarity
	var rarity: String = "Common"
	if stage_num >= 3:
		rarity = "Rare"
	elif stage_num >= 2:
		rarity = "Uncommon"
	rarity_label.text = rarity.to_upper()
	
	# Update rarity pill color
	var rarity_colors: Dictionary = {
		"Common": Color(0.4, 0.4, 0.4, 1),
		"Uncommon": Color(0.204, 0.827, 0.6, 1),
		"Rare": Color(0.518, 0.208, 0.831, 1),
	}
	if rarity_colors.has(rarity):
		rarity_pill.modulate = rarity_colors[rarity]

func _populate_stats() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var stage_id: String = monster_data.get("stageId", "stage_1")
	var stage_num: int = _get_stage_number(stage_id)
	
	# Simple attack and energy based on stage
	attack_value.text = str(stage_num * 50)
	energy_value.text = str(stage_num * 40)

func _populate_about() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var species_id: String = monster_data.get("speciesId", "dino")
	about_body.text = DESCRIPTIONS.get(species_id, "A wonderful companion!")

func _populate_cta() -> void:
	cta_button.text = "✨  Evolve This Creature"

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
# HELPERS
# ---------------------------------------------------------------------------
func _get_stage_number(stage_id: String) -> int:
	match stage_id:
		"stage_0":
			return 0
		"stage_1":
			return 1
		"stage_2":
			return 2
		"stage_3":
			return 3
		"stage_4":
			return 4
		_:
			return 1

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	if GameManager:
		GameManager.change_screen("Collection")

func _on_cta_down() -> void:
	_cta_base_y = cta_button.position.y
	var tween = create_tween()
	tween.tween_property(cta_button, "position:y", _cta_base_y + 4.0, 0.06)

func _on_cta_up() -> void:
	var tween = create_tween()
	tween.tween_property(cta_button, "position:y", _cta_base_y, 0.08)

func _on_cta_pressed() -> void:
	if GameManager:
		GameManager.change_screen("Evolution", {"creature_id": _monster_id})

func _on_tab_pressed(tab_name: String) -> void:
	bottom_nav.set_active(tab_name)
	match tab_name:
		"Home":
			if GameManager:
				GameManager.change_screen("Home")
		"Collection":
			if GameManager:
				GameManager.change_screen("Collection")
		"Shop":
			if GameManager:
				GameManager.change_screen("Shop")
