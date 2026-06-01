extends Control

# ── Palette ────────────────────────────────────────────────────────────────────
const COLOR_PRIMARY        := Color(0.420, 0.220, 0.831, 1.0)  # #6b38d4
const COLOR_PRIMARY_DARK   := Color(0.333, 0.086, 0.745, 1.0)  # #5516be
const COLOR_PRIMARY_CTR    := Color(0.518, 0.333, 0.937, 1.0)  # #8455ef
const COLOR_PRIMARY_FIXED  := Color(0.914, 0.867, 1.000, 1.0)  # #e9ddff
const COLOR_SURFACE        := Color(1.000, 1.000, 1.000, 1.0)
const COLOR_SURF_SOFT      := Color(0.953, 0.957, 0.965, 1.0)  # #F3F4F6
const COLOR_OUTLINE        := Color(0.176, 0.176, 0.176, 1.0)  # #2D2D2D
const COLOR_ON_SURF_VAR    := Color(0.286, 0.267, 0.329, 1.0)
const COLOR_ON_SURFACE     := Color(0.098, 0.110, 0.114, 1.0)
const COLOR_EGG_YELLOW     := Color(0.992, 0.878, 0.278, 1.0)
const COLOR_GREEN          := Color(0.204, 0.831, 0.600, 1.0)
const COLOR_SEC_FIXED      := Color(0.435, 0.984, 0.733, 1.0)  # #6ffbbe
const COLOR_ON_SEC_FX_VAR  := Color(0.000, 0.321, 0.212, 1.0)  # #005236
const COLOR_ON_PRI_FX_VAR  := Color(0.333, 0.086, 0.745, 1.0)  # #5516be

# ── Nodes (cached) ─────────────────────────────────────────────────────────────
@onready var modal_card      := $ModalContainer/ModalCard
@onready var floating_badge  := $ModalContainer/FloatingBadge
@onready var creature_emoji  := $ModalContainer/ModalCard/ModalVBox/CreatureCard/CreatureVBox/CreatureEmoji
@onready var continue_btn    := $ModalContainer/ModalCard/ModalVBox/ContinueButton
@onready var confetti_layer  := $ConfettiLayer
@onready var confetti_timer  := $ConfettiTimer
@onready var dim_bg          := $DimBackground
@onready var top_appbar      := $TopAppBar
@onready var bottom_nav      := $BottomNav

# ── State ──────────────────────────────────────────────────────────────────────
var _float_tween  : Tween
var _badge_tween  : Tween

func _ready() -> void:
	_populate_creature_data()
	_apply_styles()
	_animate_modal_in()
	_start_floating(creature_emoji)
	_start_badge_float()
	_spawn_confetti_burst()
	confetti_timer.timeout.connect(_spawn_confetti_burst)
	continue_btn.pressed.connect(_on_continue_pressed)

	# Set bottom nav active tab to merge and hide start button
	bottom_nav.set_active("merge")
	bottom_nav.start_button.visible = false


# ── Data Population ─────────────────────────────────────────────────────────────
func _populate_creature_data() -> void:
	var rewards: Dictionary = GameState.session_rewards
	var creature_id: String = rewards.get("merged_creature", "")

	if creature_id == "":
		push_error("No merged creature found in session_rewards")
		return

	# Creature symbols and IDs
	var symbols: Array[String] = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
	var creature_ids: Array[String] = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]

	var idx: int = creature_ids.find(creature_id)
	if idx == -1:
		idx = creature_id.hash() % symbols.size()

	# Update creature emoji and name
	creature_emoji.text = symbols[idx]
	var creature_name_label: Label = $ModalContainer/ModalCard/ModalVBox/CreatureCard/CreatureVBox/CreatureName
	creature_name_label.text = MergeSystem.get_creature_name(creature_id)

	# Update stats based on evolution level
	var level: int = MergeSystem.get_evolution_level(creature_id)
	var attack_value: Label = $ModalContainer/ModalCard/ModalVBox/StatsGrid/AttackStat/AttackVBox/AttackValue
	var energy_value: Label = $ModalContainer/ModalCard/ModalVBox/StatsGrid/EnergyStat/EnergyVBox/EnergyValue
	attack_value.text = str(level * 42)
	energy_value.text = str(level * 31)

	# Update currency display
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)


# ── Styles ─────────────────────────────────────────────────────────────────────
func _apply_styles() -> void:
	_style_modal_card()
	_style_floating_badge()
	_style_creature_card()
	_style_tags()
	_style_stat_cards()
	_style_continue_button()


func _style_modal_card() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_SURFACE
	s.border_color = COLOR_OUTLINE
	s.set_border_width_all(4)
	s.corner_radius_top_left     = 32
	s.corner_radius_top_right    = 32
	s.corner_radius_bottom_left  = 32
	s.corner_radius_bottom_right = 32
	modal_card.add_theme_stylebox_override("panel", s)


func _style_floating_badge() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_EGG_YELLOW
	s.border_color = COLOR_OUTLINE
	s.set_border_width_all(4)
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	s.shadow_color  = COLOR_OUTLINE
	s.shadow_offset = Vector2(0, 4)
	s.shadow_size   = 0
	floating_badge.add_theme_stylebox_override("panel", s)
	floating_badge.custom_minimum_size = Vector2(80, 80)


func _style_creature_card() -> void:
	var card := $ModalContainer/ModalCard/ModalVBox/CreatureCard
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_SURFACE
	s.border_color = COLOR_OUTLINE
	s.set_border_width_all(4)
	s.corner_radius_top_left     = 24
	s.corner_radius_top_right    = 24
	s.corner_radius_bottom_left  = 24
	s.corner_radius_bottom_right = 24
	s.shadow_color  = COLOR_OUTLINE
	s.shadow_offset = Vector2(0, 4)
	s.shadow_size   = 0
	card.add_theme_stylebox_override("panel", s)


func _style_tags() -> void:
	var water_tag := $ModalContainer/ModalCard/ModalVBox/CreatureCard/CreatureVBox/TagsHBox/WaterTag
	var rare_tag  := $ModalContainer/ModalCard/ModalVBox/CreatureCard/CreatureVBox/TagsHBox/RareTag

	for pair in [[water_tag, COLOR_SEC_FIXED], [rare_tag, COLOR_PRIMARY_FIXED]]:
		var panel := pair[0] as PanelContainer
		var bg    : Color = pair[1]
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = COLOR_OUTLINE
		s.set_border_width_all(2)
		s.corner_radius_top_left     = 999
		s.corner_radius_top_right    = 999
		s.corner_radius_bottom_left  = 999
		s.corner_radius_bottom_right = 999
		panel.add_theme_stylebox_override("panel", s)


func _style_stat_cards() -> void:
	var attack := $ModalContainer/ModalCard/ModalVBox/StatsGrid/AttackStat
	var energy := $ModalContainer/ModalCard/ModalVBox/StatsGrid/EnergyStat
	for stat in [attack, energy]:
		var s := StyleBoxFlat.new()
		s.bg_color = COLOR_SURF_SOFT
		s.border_color = COLOR_OUTLINE
		s.set_border_width_all(2)
		s.corner_radius_top_left     = 16
		s.corner_radius_top_right    = 16
		s.corner_radius_bottom_left  = 16
		s.corner_radius_bottom_right = 16
		stat.add_theme_stylebox_override("panel", s)


func _style_continue_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PRIMARY
	normal.border_color = COLOR_OUTLINE
	normal.set_border_width_all(4)
	normal.corner_radius_top_left     = 999
	normal.corner_radius_top_right    = 999
	normal.corner_radius_bottom_left  = 999
	normal.corner_radius_bottom_right = 999
	normal.shadow_color  = COLOR_PRIMARY_DARK
	normal.shadow_offset = Vector2(0, 4)
	normal.shadow_size   = 0

	var pressed_s := normal.duplicate() as StyleBoxFlat
	pressed_s.shadow_offset = Vector2(0, 0)

	var hover_s := normal.duplicate() as StyleBoxFlat
	hover_s.bg_color = COLOR_PRIMARY_CTR

	continue_btn.add_theme_stylebox_override("normal",  normal)
	continue_btn.add_theme_stylebox_override("pressed", pressed_s)
	continue_btn.add_theme_stylebox_override("hover",   hover_s)
	continue_btn.add_theme_color_override("font_color",         Color.WHITE)
	continue_btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	continue_btn.add_theme_color_override("font_pressed_color", Color.WHITE)


# ── Modal entrance animation ───────────────────────────────────────────────────
func _animate_modal_in() -> void:
	modal_card.scale = Vector2(0.95, 0.95)
	modal_card.modulate.a = 0.0
	dim_bg.modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(modal_card, "scale",       Vector2.ONE,  0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(modal_card, "modulate:a",  1.0,          0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(dim_bg,     "modulate:a",  1.0,          0.30).set_ease(Tween.EASE_OUT)


# ── Floating animation (creature & badge) ──────────────────────────────────────
func _start_floating(node: Control) -> void:
	var origin_y: float = node.position.y
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(node, "position:y", origin_y - 10.0, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(node, "position:y", origin_y,         1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _start_badge_float() -> void:
	# Position badge centered above modal card, overlapping top edge
	await get_tree().process_frame
	await get_tree().process_frame
	var card_rect: Rect2 = modal_card.get_global_rect()
	floating_badge.global_position = Vector2(
		card_rect.position.x + card_rect.size.x * 0.5 - 40.0,
		card_rect.position.y - 40.0
	)
	_badge_tween = create_tween().set_loops()
	var base_y: float = floating_badge.global_position.y
	_badge_tween.tween_property(floating_badge, "global_position:y", base_y - 8.0, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_badge_tween.tween_property(floating_badge, "global_position:y", base_y,       1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# ── Confetti ───────────────────────────────────────────────────────────────────
const CONFETTI_COLORS := [
	Color(0.420, 0.220, 0.831, 1),
	Color(0.204, 0.831, 0.600, 1),
	Color(0.925, 0.286, 0.600, 1),
	Color(0.992, 0.878, 0.278, 1),
	Color(0.655, 0.545, 0.980, 1),
]

func _spawn_confetti_burst() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	for _i in range(50):
		var rect := ColorRect.new()
		rect.size  = Vector2(8, 8)
		rect.color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
		rect.position = Vector2(randf() * vp_size.x, -10.0)
		confetti_layer.add_child(rect)

		var dur: float = randf_range(2.0, 5.0)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(rect, "position:y",       vp_size.y + 10.0,        dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(rect, "rotation_degrees", randf_range(0.0, 720.0), dur)
		tw.tween_property(rect, "modulate:a",       0.0,                     dur * 0.8).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(rect.queue_free)


# ── CONTINUE handler ───────────────────────────────────────────────────────────
func _on_continue_pressed() -> void:
	NavigationManager.pop_overlay()
