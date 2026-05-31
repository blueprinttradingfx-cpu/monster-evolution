extends Control
## monster_detail_screen.gd
## Controller for monster_detail_screen.tscn
## Driven by a MonsterDetailData resource passed in via load_monster().
## Handles: bounce-in entry animation, floating hero animation, sparkle burst
## on tap, press/release CTA button feedback, and nav routing.

# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------
signal back_pressed
signal merge_more_pressed(monster_name: String)
signal nav_play_pressed
signal nav_merge_pressed
signal nav_shop_pressed

# ---------------------------------------------------------------------------
# INNER CLASS — MonsterDetailData
# ---------------------------------------------------------------------------
## Passed in from the collection screen (or any caller) to populate the UI.
class MonsterDetailData:
	var id: int
	var name: String
	var rarity: String         ## "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
	var evolution_stage: int
	var attack: int
	var energy: int
	var description: String
	var emoji: String
	var texture: Texture2D
	## Recipe: array of dicts, each with keys "name", "emoji", "texture"
	var recipe: Array          ## e.g. [{"name":"Blob","emoji":"🟢"},{"name":"Blob","emoji":"🟢"}]
	var result_name: String    ## Name of the merge result (usually self)
	var result_emoji: String
	var result_texture: Texture2D
	var coins: int
	var eggs: int

	func _init() -> void:
		id              = 4
		name            = "Sparkle Blob"
		rarity          = "Rare"
		evolution_stage = 2
		attack          = 124
		energy          = 89
		description     = "A shimmering slime that glows brighter when it's happy. It loves to bounce and leave a trail of glitter wherever it goes."
		emoji           = "✨"
		texture         = null
		recipe          = [
			{"name": "Blob", "emoji": "🟢", "texture": null},
			{"name": "Blob", "emoji": "🟢", "texture": null},
		]
		result_name     = "Sparkle Blob"
		result_emoji    = "✨"
		result_texture  = null
		coins           = 1250
		eggs            = 5

# ---------------------------------------------------------------------------
# RARITY → colour map
# ---------------------------------------------------------------------------
const RARITY_COLORS: Dictionary = {
	"Common":    Color(0.400, 0.400, 0.400, 1),
	"Uncommon":  Color(0.204, 0.827, 0.600, 1),
	"Rare":      Color(0.584, 0.431, 0.0,   1),
	"Epic":      Color(0.518, 0.208, 0.831, 1),
	"Legendary": Color(0.937, 0.455, 0.067, 1),
}

# ---------------------------------------------------------------------------
# EXPORT
# ---------------------------------------------------------------------------
## Seconds for the hero image to complete one float cycle (up → down → up).
@export var float_period: float = 3.0

## Pixels the hero image rises on each float peak.
@export var float_amplitude: float = 10.0

## Seconds the bounce-in entry animation takes.
@export var bounce_in_duration: float = 0.5

## Number of sparkle labels burst on hero tap.
@export var sparkle_count: int = 8

## Sparkle burst radius (px).
@export var sparkle_radius: float = 90.0

# ---------------------------------------------------------------------------
# NODE REFS — HEADER
# ---------------------------------------------------------------------------
@onready var back_button: Button    = $Header/HeaderRow/BackButton
@onready var header_title: Label    = $Header/HeaderRow/HeaderTitle
@onready var currency_label: Label  = $Header/HeaderRow/CurrencyPill/CurrencyLabel

# ---------------------------------------------------------------------------
# NODE REFS — HERO
# ---------------------------------------------------------------------------
@onready var hero_section: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection
@onready var image_container: CenterContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer
@onready var monster_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer/MonsterImage
@onready var monster_emoji: Label       = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/ImageContainer/MonsterEmoji
@onready var rarity_label: Label        = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill/RarityLabel
@onready var rarity_pill: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/RarityCenter/RarityPill
@onready var monster_name: Label        = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/MonsterNameCenter/MonsterName
@onready var evo_stage_label: Label     = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/HeroSection/HeroVBox/HeroInfoVBox/EvoPillCenter/EvoPill/EvoPillHBox/EvoStageLabel

# ---------------------------------------------------------------------------
# NODE REFS — STATS
# ---------------------------------------------------------------------------
@onready var attack_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/AttackCard/AttackVBox/AttackValue
@onready var energy_value: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/StatsSection/EnergyCard/EnergyVBox/EnergyValue

# ---------------------------------------------------------------------------
# NODE REFS — ABOUT
# ---------------------------------------------------------------------------
@onready var about_body: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/AboutSection/AboutVBox/AboutBody

# ---------------------------------------------------------------------------
# NODE REFS — EVOLUTION GUIDE
# ---------------------------------------------------------------------------
@onready var ingredient1_emoji: Label    = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Bubble/Ingredient1Emoji
@onready var ingredient1_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Bubble/Ingredient1Image
@onready var ingredient1_label: Label   = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient1VBox/Ingredient1Label
@onready var ingredient2_emoji: Label    = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Bubble/Ingredient2Emoji
@onready var ingredient2_image: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Bubble/Ingredient2Image
@onready var ingredient2_label: Label   = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/Ingredient2VBox/Ingredient2Label
@onready var result_emoji_node: Label   = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultBubble/ResultEmoji
@onready var result_image_node: TextureRect = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultBubble/ResultImage
@onready var result_label_node: Label   = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/EvoSection/EvoPanel/EvoHBox/ResultVBox/ResultLabel

# ---------------------------------------------------------------------------
# NODE REFS — CTA
# ---------------------------------------------------------------------------
@onready var cta_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/InnerVBox/CtaButton

# ---------------------------------------------------------------------------
# NODE REFS — SPARKLE LAYER
# ---------------------------------------------------------------------------
@onready var sparkle_layer: Control = $SparkleLayer

# ---------------------------------------------------------------------------
# NODE REFS — NAVIGATION
# ---------------------------------------------------------------------------
@onready var nav_play: VBoxContainer       = $NavBar/NavRow/NavPlay
@onready var nav_merge: VBoxContainer      = $NavBar/NavRow/NavMerge
@onready var nav_shop: VBoxContainer       = $NavBar/NavRow/NavShop

# ---------------------------------------------------------------------------
# PRIVATE STATE
# ---------------------------------------------------------------------------
var _data: MonsterDetailData = null
var _float_tween: Tween = null
var _float_base_y: float = 0.0
var _cta_base_y: float = 0.0

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Use default data if none was injected before adding to scene tree.
	if _data == null:
		_data = MonsterDetailData.new()

	_populate_ui()
	_play_bounce_in()
	_start_float_animation()
	_connect_signals()

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Call this BEFORE adding the scene to the tree (or immediately after) to
## inject live monster data.  Example from CollectionScreen:
##   var detail = preload("res://monster_detail_screen.tscn").instantiate()
##   detail.load_monster(my_data)
##   get_tree().root.add_child(detail)
func load_monster(data: MonsterDetailData) -> void:
	_data = data
	if is_node_ready():
		_populate_ui()

# ---------------------------------------------------------------------------
# UI POPULATION
# ---------------------------------------------------------------------------
func _populate_ui() -> void:
	_populate_header()
	_populate_hero()
	_populate_stats()
	_populate_about()
	_populate_evolution()
	_populate_cta()

func _populate_header() -> void:
	header_title.text  = _data.name
	currency_label.text = "%s 🪙  %d 🥚" % [_format_number(_data.coins), _data.eggs]

func _populate_hero() -> void:
	monster_name.text      = _data.name
	evo_stage_label.text   = "Evolution Stage: %d" % _data.evolution_stage
	rarity_label.text      = _data.rarity.to_upper()

	# Rarity pill colour
	if RARITY_COLORS.has(_data.rarity):
		var sb := rarity_pill.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sb:
			sb.bg_color = RARITY_COLORS[_data.rarity]
			rarity_pill.add_theme_stylebox_override("panel", sb)

	# Monster sprite / emoji
	if _data.texture:
		monster_image.texture = _data.texture
		monster_image.visible = true
		monster_emoji.visible = false
	else:
		monster_emoji.text    = _data.emoji
		monster_emoji.visible = true
		monster_image.visible = false

func _populate_stats() -> void:
	attack_value.text = str(_data.attack)
	energy_value.text = str(_data.energy)

func _populate_about() -> void:
	about_body.text = _data.description

func _populate_evolution() -> void:
	# Ingredient 1
	if _data.recipe.size() > 0:
		var r0: Dictionary = _data.recipe[0]
		ingredient1_label.text = r0.get("name", "?")
		if r0.get("texture") != null:
			ingredient1_image.texture = r0["texture"]
			ingredient1_image.visible = true
			ingredient1_emoji.visible = false
		else:
			ingredient1_emoji.text    = r0.get("emoji", "❓")
			ingredient1_emoji.visible = true
			ingredient1_image.visible = false

	# Ingredient 2
	if _data.recipe.size() > 1:
		var r1: Dictionary = _data.recipe[1]
		ingredient2_label.text = r1.get("name", "?")
		if r1.get("texture") != null:
			ingredient2_image.texture = r1["texture"]
			ingredient2_image.visible = true
			ingredient2_emoji.visible = false
		else:
			ingredient2_emoji.text    = r1.get("emoji", "❓")
			ingredient2_emoji.visible = true
			ingredient2_image.visible = false

	# Result
	result_label_node.text = _data.result_name
	if _data.result_texture:
		result_image_node.texture = _data.result_texture
		result_image_node.visible = true
		result_emoji_node.visible = false
	else:
		result_emoji_node.text    = _data.result_emoji
		result_emoji_node.visible = true
		result_image_node.visible = false

func _populate_cta() -> void:
	cta_button.text = "🪄  Merge More %ss" % _data.name

# ---------------------------------------------------------------------------
# ANIMATIONS
# ---------------------------------------------------------------------------

## CSS .bounce-in equivalent — scale 0.9 → 1 with overshoot easing.
func _play_bounce_in() -> void:
	hero_section.scale = Vector2(0.9, 0.9)
	hero_section.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(hero_section, "scale", Vector2(1.0, 1.0), bounce_in_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(hero_section, "modulate:a", 1.0, bounce_in_duration * 0.6) \
		.set_ease(Tween.EASE_OUT)

## CSS .floating infinite loop — translateY 0 → -amplitude → 0.
func _start_float_animation() -> void:
	_float_base_y = image_container.position.y
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.set_loops()
	_float_tween.tween_property(
		image_container, "position:y",
		_float_base_y - float_amplitude,
		float_period * 0.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(
		image_container, "position:y",
		_float_base_y,
		float_period * 0.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

## JS sparkle burst — spawns emoji Labels that fly outward and fade.
func _burst_sparkles(origin: Vector2) -> void:
	var sparkle_chars := ["✨", "⭐", "💫", "🌟"]
	var sparkle_colors := [
		Color(0.655, 0.545, 0.980, 1),  # creature-purple
		Color(0.992, 0.878, 0.133, 1),  # egg-yellow
		Color(0.204, 0.827, 0.600, 1),  # growth-green
		Color(0.925, 0.286, 0.600, 1),  # evolution-pink
	]

	for i in sparkle_count:
		var lbl := Label.new()
		lbl.text = sparkle_chars[i % sparkle_chars.size()]
		lbl.theme_override_font_sizes["font_size"] = 20
		lbl.theme_override_colors["font_color"] = sparkle_colors[i % sparkle_colors.size()]
		lbl.position = origin
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle_layer.add_child(lbl)

		var angle := (float(i) / float(sparkle_count)) * TAU
		var dist  := sparkle_radius + randf() * 40.0
		var target := origin + Vector2(cos(angle), sin(angle)) * dist

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(lbl, "position", target, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		tw.tween_property(lbl, "scale", Vector2(0.2, 0.2), 0.6).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(lbl.queue_free)

# ---------------------------------------------------------------------------
# SIGNAL CONNECTIONS
# ---------------------------------------------------------------------------
func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	cta_button.pressed.connect(_on_cta_pressed)
	cta_button.button_down.connect(_on_cta_down)
	cta_button.button_up.connect(_on_cta_up)

	# Hero tap → sparkle burst
	image_container.gui_input.connect(_on_hero_gui_input)

	# Nav tabs
	nav_play.gui_input.connect(_on_nav_play_input)
	nav_merge.gui_input.connect(_on_nav_merge_input)
	nav_shop.gui_input.connect(_on_nav_shop_input)

# ---------------------------------------------------------------------------
# HANDLERS — HEADER
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	back_pressed.emit()
	## Uncomment for direct scene pop:
	# get_tree().change_scene_to_file("res://scenes/collection_screen.tscn")

# ---------------------------------------------------------------------------
# HANDLERS — HERO TAP
# ---------------------------------------------------------------------------
func _on_hero_gui_input(event: InputEvent) -> void:
	if _is_tap_released(event):
		var center := image_container.global_position + image_container.size * 0.5
		_burst_sparkles(center)

# ---------------------------------------------------------------------------
# HANDLERS — CTA BUTTON
# ---------------------------------------------------------------------------
func _on_cta_down() -> void:
	## Replicate CSS pressed-state: translateY(4px) + remove shadow.
	_cta_base_y = cta_button.position.y
	var tw := create_tween()
	tw.tween_property(cta_button, "position:y", _cta_base_y + 4.0, 0.06)

func _on_cta_up() -> void:
	var tw := create_tween()
	tw.tween_property(cta_button, "position:y", _cta_base_y, 0.08)

func _on_cta_pressed() -> void:
	merge_more_pressed.emit(_data.name)
	## Example: navigate to merge screen filtered by this monster type:
	# get_tree().change_scene_to_file("res://scenes/merge_screen.tscn")

# ---------------------------------------------------------------------------
# HANDLERS — NAVIGATION
# ---------------------------------------------------------------------------
func _on_nav_play_input(event: InputEvent) -> void:
	if _is_tap_released(event):
		nav_play_pressed.emit()
		# get_tree().change_scene_to_file("res://scenes/play_screen.tscn")

func _on_nav_merge_input(event: InputEvent) -> void:
	if _is_tap_released(event):
		nav_merge_pressed.emit()
		# get_tree().change_scene_to_file("res://scenes/merge_screen.tscn")

func _on_nav_shop_input(event: InputEvent) -> void:
	if _is_tap_released(event):
		nav_shop_pressed.emit()
		# get_tree().change_scene_to_file("res://scenes/shop_screen.tscn")

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
func _is_tap_released(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	return false

func _format_number(n: int) -> String:
	var s      := str(n)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
