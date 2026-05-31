extends Control

# ── Palette ────────────────────────────────────────────────────────────────────
const COLOR_PRIMARY        := Color(0.420, 0.220, 0.831, 1.0)  # #6b38d4
const COLOR_PRIMARY_DARK   := Color(0.333, 0.086, 0.745, 1.0)  # #5516be  (shadow)
const COLOR_PRIMARY_CTR    := Color(0.518, 0.333, 0.937, 1.0)  # #8455ef
const COLOR_BG             := Color(0.973, 0.976, 0.980, 1.0)  # #f8f9fa
const COLOR_SURFACE        := Color(1.000, 1.000, 1.000, 1.0)  # #ffffff
const COLOR_OUTLINE        := Color(0.176, 0.176, 0.176, 1.0)  # #2D2D2D
const COLOR_ON_SURF_VAR    := Color(0.286, 0.267, 0.329, 1.0)  # #494454
const COLOR_ON_SURFACE     := Color(0.098, 0.110, 0.114, 1.0)  # #191c1d
const COLOR_EGG_YELLOW     := Color(0.992, 0.878, 0.278, 1.0)  # #FDE047
const COLOR_COIN_GOLD      := Color(0.973, 0.741, 0.133, 1.0)  # #f9bd22
const COLOR_PURPLE_SOFT    := Color(0.655, 0.545, 0.980, 1.0)  # #A78BFA
const COLOR_GREEN           := Color(0.204, 0.831, 0.600, 1.0)  # #34D399
const COLOR_SURF_SOFT      := Color(0.953, 0.957, 0.965, 1.0)  # #F3F4F6
const COLOR_NAV_ACTIVE_BG  := Color(0.518, 0.333, 0.937, 1.0)  # #8455ef
const COLOR_NAV_ACTIVE_FG  := Color(1.000, 1.000, 1.000, 1.0)

# ── State ──────────────────────────────────────────────────────────────────────
var progress_target: float = 0.60   # 60 %
var progress_current: float = 0.0

# bounce tween for the header label
var _bounce_tween: Tween

func _ready() -> void:
	_apply_styles()
	_animate_progress_bar()
	_start_header_bounce()
	_spawn_confetti_burst()
	$ConfettiTimer.timeout.connect(_spawn_confetti_burst)
	$MainLayout/ScrollContent/ContentVBox/NextButtonContainer/NextButton.pressed.connect(_on_next_pressed)


# ── Styling ────────────────────────────────────────────────────────────────────
func _apply_styles() -> void:
	# Top bar background
	var topbar_style := StyleBoxFlat.new()
	topbar_style.bg_color = COLOR_SURFACE
	topbar_style.border_color = COLOR_OUTLINE
	topbar_style.border_width_bottom = 4
	$MainLayout/TopBar.add_theme_stylebox_override("panel", topbar_style)

	# Reward cards
	var card_paths := [
		"MainLayout/ScrollContent/ContentVBox/RewardCards/EggCard",
		"MainLayout/ScrollContent/ContentVBox/RewardCards/CoinCard",
		"MainLayout/ScrollContent/ContentVBox/RewardCards/XpCard",
	]
	var card_icon_colors := [COLOR_EGG_YELLOW, COLOR_COIN_GOLD, COLOR_PURPLE_SOFT]
	for i in range(card_paths.size()):
		_style_reward_card(get_node(card_paths[i]), card_icon_colors[i])

	# Progress bar background
	var prog_bg_style := StyleBoxFlat.new()
	prog_bg_style.bg_color    = COLOR_SURF_SOFT
	prog_bg_style.border_color = COLOR_OUTLINE
	prog_bg_style.set_border_width_all(4)
	prog_bg_style.corner_radius_top_left     = 32
	prog_bg_style.corner_radius_top_right    = 32
	prog_bg_style.corner_radius_bottom_left  = 32
	prog_bg_style.corner_radius_bottom_right = 32
	$MainLayout/ScrollContent/ContentVBox/EvolutionSection/ProgressBarBG.add_theme_stylebox_override("panel", prog_bg_style)

	# Progress bar fill colour (will be resized in _animate_progress_bar)
	$MainLayout/ScrollContent/ContentVBox/EvolutionSection/ProgressBarBG/ProgressBarFill.color = COLOR_GREEN

	# NEXT button
	_style_next_button()

	# Bottom nav
	_style_bottom_nav()

	# Bottom nav highlight on "Play"
	var play_nav := $MainLayout/BottomNav/NavHBox/PlayNav
	var play_bg := StyleBoxFlat.new()
	play_bg.bg_color = COLOR_NAV_ACTIVE_BG
	play_bg.corner_radius_top_left     = 12
	play_bg.corner_radius_top_right    = 12
	play_bg.corner_radius_bottom_left  = 12
	play_bg.corner_radius_bottom_right = 12
	play_nav.add_theme_stylebox_override("panel", play_bg)
	$MainLayout/BottomNav/NavHBox/PlayNav/PlayLabel.add_theme_color_override("font_color", COLOR_NAV_ACTIVE_FG)


func _style_reward_card(card: PanelContainer, icon_bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color    = COLOR_SURFACE
	style.border_color = COLOR_OUTLINE
	style.set_border_width_all(4)
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = COLOR_OUTLINE
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size   = 0
	card.add_theme_stylebox_override("panel", style)

	# Colour the icon box inside
	var icon_panel: PanelContainer = card.get_child(0).get_child(0)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color    = icon_bg
	icon_style.border_color = COLOR_OUTLINE
	icon_style.set_border_width_all(2)
	icon_style.corner_radius_top_left     = 8
	icon_style.corner_radius_top_right    = 8
	icon_style.corner_radius_bottom_left  = 8
	icon_style.corner_radius_bottom_right = 8
	icon_panel.add_theme_stylebox_override("panel", icon_style)


func _style_next_button() -> void:
	var btn := $MainLayout/ScrollContent/ContentVBox/NextButtonContainer/NextButton

	var normal := StyleBoxFlat.new()
	normal.bg_color    = COLOR_PRIMARY
	normal.border_color = COLOR_OUTLINE
	normal.set_border_width_all(4)
	normal.corner_radius_top_left     = 999
	normal.corner_radius_top_right    = 999
	normal.corner_radius_bottom_left  = 999
	normal.corner_radius_bottom_right = 999
	normal.shadow_color  = COLOR_PRIMARY_DARK
	normal.shadow_offset = Vector2(0, 4)
	normal.shadow_size   = 0

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.shadow_offset = Vector2(0, 0)

	var hover_style := normal.duplicate() as StyleBoxFlat
	hover_style.bg_color = COLOR_PRIMARY_CTR

	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_color_override("font_color",         Color.WHITE)
	btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)


func _style_bottom_nav() -> void:
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color    = COLOR_SURFACE
	nav_style.border_color = COLOR_OUTLINE
	nav_style.border_width_top = 4
	nav_style.corner_radius_top_left  = 12
	nav_style.corner_radius_top_right = 12
	$MainLayout/BottomNav.add_theme_stylebox_override("panel", nav_style)


# ── Progress bar animation ─────────────────────────────────────────────────────
func _animate_progress_bar() -> void:
	var fill := $MainLayout/ScrollContent/ContentVBox/EvolutionSection/ProgressBarBG/ProgressBarFill
	# Start at zero width and tween to 60 %
	fill.size.x = 0.0

	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void:
			# Recalculate each frame since parent may not be laid-out yet on first frame
			var parent_w: float = fill.get_parent().size.x
			fill.size.x = parent_w * v
			fill.size.y = fill.get_parent().size.y,
		0.0,
		progress_target,
		1.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


# ── Header bounce ──────────────────────────────────────────────────────────────
func _start_header_bounce() -> void:
	var label := $MainLayout/ScrollContent/ContentVBox/VictoryHeader/LevelCompleteLabel
	_bounce_tween = create_tween().set_loops()
	_bounce_tween.tween_property(label, "position:y", label.position.y - 8, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bounce_tween.tween_property(label, "position:y", label.position.y,     0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# ── Confetti ───────────────────────────────────────────────────────────────────
const CONFETTI_COLORS := [
	Color(0.420, 0.220, 0.831, 1),  # primary
	Color(0.204, 0.831, 0.600, 1),  # green
	Color(0.992, 0.878, 0.278, 1),  # yellow
	Color(0.925, 0.286, 0.600, 1),  # pink
	Color(0.655, 0.545, 0.980, 1),  # purple soft
]

func _spawn_confetti_burst() -> void:
	var layer: Node2D = $ConfettiLayer
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	for i in range(40):
		var c := ColorRect.new()
		c.size = Vector2(8, 8)
		c.color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
		if randf() > 0.5:
			# circle-ish: use a square with a script rounding via shader-free trick — just leave square for perf
			pass
		c.position = Vector2(randf() * viewport_size.x, -20.0)
		layer.add_child(c)

		var duration := randf_range(2.0, 4.0)
		var rot_deg  := randf_range(0.0, 720.0)
		var tween    := create_tween()
		tween.set_parallel(true)
		tween.tween_property(c, "position:y", viewport_size.y + 20.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(c, "rotation_degrees", rot_deg, duration)
		tween.tween_property(c, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(c.queue_free)


# ── Button handler ─────────────────────────────────────────────────────────────
func _on_next_pressed() -> void:
	# Replace with scene transition as needed:
	# get_tree().change_scene_to_file("res://NextScreen.tscn")
	print("NEXT pressed — transition here")
