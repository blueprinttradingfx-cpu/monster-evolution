extends Control
# Creature Detail - Shows monster details and allows cosmetic equipping
# Per TICKET-26

signal cosmetic_equipped(monster_id: String, slot: String, cosmetic_id: String)

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
@onready var back_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/BackButton
@onready var top_appbar: Control = $RootLayout/TopAppBar
@onready var monster_display: PetDisplay = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection/HeroVBox/ImageContainer/MonsterDisplay
@onready var rarity_label: Label = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill/RarityLabel
@onready var rarity_pill: PanelContainer = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill
@onready var monster_name: Label = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection/HeroVBox/HeroInfoVBox/MonsterNameCenter/MonsterName
@onready var evo_stage_label: Label = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection/HeroVBox/HeroInfoVBox/EvoPillCenter/EvoPill/EvoPillHBox/EvoStageLabel
@onready var attack_value: Label = $RootLayout/ScrollContainer/SafeArea/Main/StatsSection/AttackCard/AttackVBox/AttackValue
@onready var energy_value: Label = $RootLayout/ScrollContainer/SafeArea/Main/StatsSection/EnergyCard/EnergyVBox/EnergyValue
@onready var about_body: Label = $RootLayout/ScrollContainer/SafeArea/Main/AboutSection/AboutVBox/AboutBody
@onready var cta_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/CtaButton
@onready var head_value: Label = $RootLayout/ScrollContainer/SafeArea/Main/CosmeticSlotsSection/CosmeticSlotsVBox/SlotList/HeadSlot/HeadValue
@onready var face_value: Label = $RootLayout/ScrollContainer/SafeArea/Main/CosmeticSlotsSection/CosmeticSlotsVBox/SlotList/FaceSlot/FaceValue
@onready var body_value: Label = $RootLayout/ScrollContainer/SafeArea/Main/CosmeticSlotsSection/CosmeticSlotsVBox/SlotList/BodySlot/BodyValue
@onready var equip_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/CosmeticSlotsSection/CosmeticSlotsVBox/EquipButton
@onready var sparkle_layer: Control = $SparkleLayer
@onready var bottom_nav: Control = $RootLayout/BottomNav

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
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if cta_button:
		cta_button.pressed.connect(_on_cta_pressed)
	if equip_button:
		equip_button.pressed.connect(_on_equip_pressed)
	if bottom_nav:
		bottom_nav.tab_changed.connect(_on_tab_pressed)
	
	# Setup BottomNav
	if bottom_nav:
		bottom_nav.set_active("Collection")
	
	# Set all label font sizes to 24px
	if rarity_label:
		rarity_label.add_theme_font_size_override("font_size", 24)
	if monster_name:
		monster_name.add_theme_font_size_override("font_size", 24)
	if evo_stage_label:
		evo_stage_label.add_theme_font_size_override("font_size", 24)
	if attack_value:
		attack_value.add_theme_font_size_override("font_size", 24)
	if energy_value:
		energy_value.add_theme_font_size_override("font_size", 24)
	if about_body:
		about_body.add_theme_font_size_override("font_size", 24)
	
	# Set all button font sizes to 24px
	if back_button:
		back_button.add_theme_font_size_override("font_size", 24)
	if cta_button:
		cta_button.add_theme_font_size_override("font_size", 24)

# ---------------------------------------------------------------------------
# UI POPULATION
# ---------------------------------------------------------------------------
func _populate_ui() -> void:
	if _monster_id == "":
		return
	
	_populate_header()
	_populate_hero()
	_populate_cosmetics()
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
	if species and monster_name:
		monster_name.text = species.name
	elif monster_name:
		monster_name.text = species_id.capitalize()
	
	# Update evolution stage
	if evo_stage_label:
		evo_stage_label.text = "Stage: %s" % STAGE_NAMES[stage_num]
	
	# Update rarity
	var rarity: String = "Common"
	if stage_num >= 3:
		rarity = "Rare"
	elif stage_num >= 2:
		rarity = "Uncommon"
	if rarity_label:
		rarity_label.text = rarity.to_upper()
	
	# Update rarity pill color
	var rarity_colors: Dictionary = {
		"Common": Color(0.4, 0.4, 0.4, 1),
		"Uncommon": Color(0.204, 0.827, 0.6, 1),
		"Rare": Color(0.518, 0.208, 0.831, 1),
	}
	if rarity_colors.has(rarity) and rarity_pill:
		rarity_pill.modulate = rarity_colors[rarity]

func _populate_cosmetics() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	if head_value:
		var head_id: String = monster_data.get("equippedHeadId", "")
		head_value.text = _get_cosmetic_name(head_id)
	
	if face_value:
		var face_id: String = monster_data.get("equippedFaceId", "")
		face_value.text = _get_cosmetic_name(face_id)
	
	if body_value:
		var body_id: String = monster_data.get("equippedBodyId", "")
		body_value.text = _get_cosmetic_name(body_id)

func _get_cosmetic_name(cosmetic_id: String) -> String:
	if cosmetic_id.is_empty():
		return "Empty"
	
	var cosmetic_path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var cosmetic: Resource = load(cosmetic_path)
	if cosmetic and cosmetic is Cosmetic:
		return cosmetic.name
	return "Unknown"

func _populate_stats() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var stage_id: String = monster_data.get("stageId", "stage_1")
	var stage_num: int = _get_stage_number(stage_id)
	
	# Simple attack and energy based on stage
	if attack_value:
		attack_value.text = str(stage_num * 50)
	if energy_value:
		energy_value.text = str(stage_num * 40)

func _populate_about() -> void:
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var species_id: String = monster_data.get("speciesId", "dino")
	if about_body:
		about_body.text = DESCRIPTIONS.get(species_id, "A wonderful companion!")

func _populate_cta() -> void:
	if cta_button:
		cta_button.text = "✨  Evolve This Creature"

# ---------------------------------------------------------------------------
# ANIMATIONS
# ---------------------------------------------------------------------------
func _play_bounce_in() -> void:
	var hero_section: PanelContainer = $RootLayout/ScrollContainer/SafeArea/Main/HeroSection
	if hero_section:
		hero_section.scale = Vector2(0.9, 0.9)
		hero_section.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(hero_section, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(hero_section, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _start_float_animation() -> void:
	if monster_display:
		_float_base_y = monster_display.position.y
		if _float_tween:
			_float_tween.kill()
		_float_tween = create_tween()
		_float_tween.set_loops()
		_float_tween.tween_property(
			monster_display, "position:y",
			_float_base_y - 10.0,
			1.5
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_float_tween.tween_property(
			monster_display, "position:y",
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
		if sparkle_layer:
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
func _play_button_press_animation(button: Button) -> void:
	if not button:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _on_back_pressed() -> void:
	_play_button_press_animation(back_button)
	if GameManager:
		GameManager.change_screen("Collection")

func _on_equip_pressed() -> void:
	_play_button_press_animation(equip_button)
	print("[CreatureDetail] Opening cosmetic selector")
	var selector_scene = load("res://scenes/screens/cosmetic-selector/CosmeticSelector.tscn")
	var selector = selector_scene.instantiate()
	add_child(selector)
	
	selector.setup(_monster_id)
	selector.cosmetic_selected.connect(_on_cosmetic_selected)
	selector.unequip_requested.connect(_on_unequip_requested)
	
	# Position selector in center
	selector.position = Vector2(size.x / 2 - selector.size.x / 2, size.y / 2 - selector.size.y / 2)

func _on_cta_pressed() -> void:
	_play_button_press_animation(cta_button)
	if GameManager:
		GameManager.change_screen("Evolution", {"creature_id": _monster_id})

func _on_cosmetic_selected(cosmetic_id: String) -> void:
	print("[CreatureDetail] Cosmetic selected: ", cosmetic_id)
	if not MonsterManager:
		return
	
	# Get the cosmetic to determine the slot
	var cosmetic_path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var cosmetic: Resource = load(cosmetic_path)
	if not cosmetic or not cosmetic is Cosmetic:
		return
	
	var slot: String = cosmetic.slot
	if MonsterManager.equip_cosmetic(_monster_id, slot, cosmetic_id):
		print("[CreatureDetail] Cosmetic equipped successfully")
		cosmetic_equipped.emit(_monster_id, slot, cosmetic_id)
		_populate_cosmetics()
		# Update monster display to show cosmetic
		if monster_display:
			var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
			monster_display.set_monster(monster_data)

func _on_unequip_requested() -> void:
	print("[CreatureDetail] Unequip requested")
	if not MonsterManager:
		return
	
	# Unequip all slots
	MonsterManager.unequip_cosmetic(_monster_id, "head")
	MonsterManager.unequip_cosmetic(_monster_id, "face")
	MonsterManager.unequip_cosmetic(_monster_id, "body")
	
	_populate_cosmetics()
	# Update monster display
	if monster_display:
		var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
		monster_display.set_monster(monster_data)

func _on_tab_pressed(tab_name: String) -> void:
	if bottom_nav:
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
