extends Control

# ─────────────────────────────────────────────
#  Merge Memory Monsters — Game Script (Godot 4)
#  Converted from HTML/Tailwind UI prototype
# ─────────────────────────────────────────────

# ── Tuning ────────────────────────────────────
const CARD_SIZE        := Vector2(72, 72)
const FLIP_DURATION    := 0.25   # seconds for half-flip
const FLIP_WAIT        := 0.8    # seconds before hiding unmatched pair
const GRID_COLS        := 4
const TOTAL_PAIRS      := 8      # 4×4 grid = 8 pairs

# Monster emoji used as card faces (one per pair)
const MONSTERS := ["🟢","🔵","🟣","🟡","🔴","🟠","⚪","🟤"]

# ── State ─────────────────────────────────────
var matches_done : int  = 0
var turn_count   : int  = 0
var elapsed_time : float = 0.0
var is_timing    : bool  = true

var card_values  : Array[int]  = []   # assigned monster index per card slot
var card_matched : Array[bool] = []   # permanently revealed
var flipped_now  : Array[int]  = []   # indices of currently face-up (unmatched) cards
var is_locked    : bool = false       # prevent clicks during flip-back animation

# Node references (resolved in _ready)
@onready var top_appbar        : TopAppBar     = $TopAppBar
@onready var bottom_nav        : BottomNav     = $BottomNav
@onready var card_grid         : GridContainer = $MainLayout/ScrollContainer/ContentArea/CardGrid
@onready var matches_label     : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/MatchesPanel/MatchesContent/MatchesValue
@onready var timer_label       : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/TimerTurns/TimerLabel
@onready var turns_label       : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/TimerTurns/TurnsLabel
@onready var progress_fill     : ColorRect     = $MainLayout/ScrollContainer/ContentArea/BonusProgressBg/BonusProgressFill
@onready var win_overlay       : CanvasLayer   = $WinOverlay
@onready var win_control       : Control       = $WinOverlay/WinControl
@onready var confetti_layer    : Node2D        = $WinOverlay/WinControl/ConfettiLayer
@onready var confetti_timer    : Timer         = $WinOverlay/WinControl/ConfettiTimer
@onready var next_button       : Button        = $WinOverlay/WinControl/WinMainLayout/WinCenterContainer/WinContent/NextButtonContainer/NextButton
@onready var egg_value_label   : Label         = $WinOverlay/WinControl/WinMainLayout/WinCenterContainer/WinContent/RewardCards/EggCard/EggHBox/EggTextVBox/EggValueLabel
@onready var coin_value_label  : Label         = $WinOverlay/WinControl/WinMainLayout/WinCenterContainer/WinContent/RewardCards/CoinCard/CoinHBox/CoinTextVBox/CoinValueLabel
@onready var progress_pct      : Label         = $WinOverlay/WinControl/WinMainLayout/WinCenterContainer/WinContent/EvolutionSection/ProgressHeader/ProgressPct
@onready var progress_bar_fill : ColorRect     = $WinOverlay/WinControl/WinMainLayout/WinCenterContainer/WinContent/EvolutionSection/ProgressBarBG/ProgressBarFill

# ── Lifecycle ─────────────────────────────────

func _ready() -> void:
	_apply_overlay_styles()
	_setup_game()
	next_button.pressed.connect(_setup_game)
	confetti_timer.timeout.connect(_spawn_confetti_burst)
	_update_hud()
	_connect_bottom_nav()
	bottom_nav.set_active("play")
	bottom_nav.start_button.visible = false

func _process(delta: float) -> void:
	if is_timing:
		elapsed_time += delta
		_refresh_timer_label()

# ── Bottom Nav Connection ─────────────────────

func _connect_bottom_nav() -> void:
	bottom_nav.tab_changed.connect(_on_tab_pressed)

func _on_tab_pressed(tab_name: String):
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

# ── Game Setup ────────────────────────────────

func _setup_game() -> void:
	# Reset state
	matches_done = 0
	turn_count   = 0
	elapsed_time = 0.0
	is_timing    = true
	is_locked    = false
	flipped_now.clear()
	win_overlay.visible = false
	confetti_timer.stop()

	# Clear any remaining confetti
	for child in confetti_layer.get_children():
		child.queue_free()

	# Build & shuffle card values
	card_values.clear()
	card_matched.clear()
	for i in TOTAL_PAIRS:
		card_values.append(i)
		card_values.append(i)
	card_values.shuffle()
	for i in card_values.size():
		card_matched.append(false)

	# Build grid
	for child in card_grid.get_children():
		child.queue_free()

	for idx in card_values.size():
		var card := _make_card(idx)
		card_grid.add_child(card)

	_update_hud()
	_refresh_progress()

# ── Card Factory ──────────────────────────────

func _make_card(idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.name = "Card_%d" % idx
	btn.text = "?"
	btn.add_theme_font_size_override("font_size", 28)

	# Style: face-down
	var style_down := StyleBoxFlat.new()
	style_down.bg_color        = Color(1, 1, 1, 1)
	style_down.border_color    = Color(0.176, 0.176, 0.176, 1)
	style_down.set_border_width_all(2)
	style_down.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", style_down)

	btn.pressed.connect(_on_card_pressed.bind(idx))
	return btn

# ── Input Handling ────────────────────────────

func _on_card_pressed(idx: int) -> void:
	if is_locked:
		return
	if card_matched[idx]:
		return
	if flipped_now.has(idx):
		return
	if flipped_now.size() >= 2:
		return

	_flip_card_up(idx)
	flipped_now.append(idx)

	if flipped_now.size() == 2:
		turn_count += 1
		_check_match()

# ── Flip Animations ───────────────────────────

func _flip_card_up(idx: int) -> void:
	var btn := card_grid.get_child(idx) as Button
	if not btn:
		return
	var monster_idx := card_values[idx]
	var tween := create_tween()
	tween.tween_property(btn, "scale:x", 0.0, FLIP_DURATION)
	tween.tween_callback(func():
		btn.text = MONSTERS[monster_idx]
		btn.add_theme_color_override("font_color", Color(0.176, 0.176, 0.176, 1))
	)
	tween.tween_property(btn, "scale:x", 1.0, FLIP_DURATION)

func _flip_card_down(idx: int) -> void:
	var btn := card_grid.get_child(idx) as Button
	if not btn:
		return
	var tween := create_tween()
	tween.tween_property(btn, "scale:x", 0.0, FLIP_DURATION)
	tween.tween_callback(func():
		btn.text = "?"
		btn.remove_theme_color_override("font_color")
	)
	tween.tween_property(btn, "scale:x", 1.0, FLIP_DURATION)

func _mark_card_matched(idx: int) -> void:
	var btn := card_grid.get_child(idx) as Button
	if not btn:
		return
	# Green border to signal a match (mirrors the HTML border-growth-green)
	var style_matched := StyleBoxFlat.new()
	style_matched.bg_color        = Color(0.878, 0.988, 0.914, 1)
	style_matched.border_color    = Color(0.204, 0.827, 0.6, 1)
	style_matched.set_border_width_all(4)
	style_matched.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", style_matched)
	btn.disabled = true

# ── Match Logic ───────────────────────────────

func _check_match() -> void:
	is_locked = true
	var a := flipped_now[0]
	var b := flipped_now[1]

	if card_values[a] == card_values[b]:
		# Match found!
		card_matched[a] = true
		card_matched[b] = true
		_mark_card_matched(a)
		_mark_card_matched(b)
		matches_done += 1
		_add_coins(50)
		flipped_now.clear()
		is_locked = false
		_update_hud()
		_refresh_progress()

		if matches_done == TOTAL_PAIRS:
			_on_win()
	else:
		# No match — wait, then flip back
		await get_tree().create_timer(FLIP_WAIT).timeout
		_flip_card_down(a)
		_flip_card_down(b)
		flipped_now.clear()
		is_locked = false

# ── Win Condition ─────────────────────────────

func _on_win() -> void:
	is_timing = false
	_add_egg()
	_add_coins(400)
	_update_hud()

	# Update overlay reward labels
	egg_value_label.text = "+1 Egg"
	coin_value_label.text = "+400 Coins"

	# Animate progress bar
	var progress_target := 0.6
	progress_bar_fill.size.x = 0.0
	progress_pct.text = "60%"
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void:
			var parent_w: float = progress_bar_fill.get_parent().size.x
			progress_bar_fill.size.x = parent_w * v
			progress_bar_fill.size.y = progress_bar_fill.get_parent().size.y,
		0.0,
		progress_target,
		1.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Start confetti
	_spawn_confetti_burst()
	confetti_timer.start()

	win_overlay.visible = true

# ── Confetti ───────────────────────────────────

const CONFETTI_COLORS := [
	Color(0.420, 0.220, 0.831, 1),
	Color(0.204, 0.831, 0.600, 1),
	Color(0.992, 0.878, 0.278, 1),
	Color(0.925, 0.286, 0.600, 1),
	Color(0.655, 0.545, 0.980, 1),
]

func _spawn_confetti_burst() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	for i in range(40):
		var c := ColorRect.new()
		c.size = Vector2(8, 8)
		c.color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
		c.position = Vector2(randf() * viewport_size.x, -20.0)
		confetti_layer.add_child(c)

		var duration := randf_range(2.0, 4.0)
		var rot_deg := randf_range(0.0, 720.0)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(c, "position:y", viewport_size.y + 20.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(c, "rotation_degrees", rot_deg, duration)
		tween.tween_property(c, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(c.queue_free)

# ── Overlay Styling ───────────────────────────

const COLOR_PRIMARY        := Color(0.420, 0.220, 0.831, 1.0)
const COLOR_PRIMARY_DARK   := Color(0.333, 0.086, 0.745, 1.0)
const COLOR_PRIMARY_CTR    := Color(0.518, 0.333, 0.937, 1.0)
const COLOR_SURFACE        := Color(1.000, 1.000, 1.000, 1.0)
const COLOR_OUTLINE        := Color(0.176, 0.176, 0.176, 1.0)
const COLOR_ON_SURF_VAR    := Color(0.286, 0.267, 0.329, 1.0)
const COLOR_ON_SURFACE     := Color(0.098, 0.110, 0.114, 1.0)
const COLOR_EGG_YELLOW     := Color(0.992, 0.878, 0.278, 1.0)
const COLOR_COIN_GOLD      := Color(0.973, 0.741, 0.133, 1.0)
const COLOR_GREEN          := Color(0.204, 0.831, 0.600, 1.0)
const COLOR_SURF_SOFT      := Color(0.953, 0.957, 0.965, 1.0)

func _apply_overlay_styles() -> void:
	# Reward cards
	var egg_card := win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/RewardCards/EggCard")
	var coin_card := win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/RewardCards/CoinCard")
	_style_reward_card(egg_card, COLOR_EGG_YELLOW)
	_style_reward_card(coin_card, COLOR_COIN_GOLD)

	# Progress bar background
	var prog_bg := win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/EvolutionSection/ProgressBarBG")
	var prog_bg_style := StyleBoxFlat.new()
	prog_bg_style.bg_color = COLOR_SURF_SOFT
	prog_bg_style.border_color = COLOR_OUTLINE
	prog_bg_style.set_border_width_all(4)
	prog_bg_style.corner_radius_top_left = 32
	prog_bg_style.corner_radius_top_right = 32
	prog_bg_style.corner_radius_bottom_left = 32
	prog_bg_style.corner_radius_bottom_right = 32
	prog_bg.add_theme_stylebox_override("panel", prog_bg_style)

	# Progress bar fill color
	progress_bar_fill.color = COLOR_GREEN

	# Next button
	_style_next_button()

func _style_reward_card(card: PanelContainer, icon_bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_OUTLINE
	style.set_border_width_all(4)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = COLOR_OUTLINE
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size = 0
	card.add_theme_stylebox_override("panel", style)

	# Color the icon box inside
	var icon_panel: PanelContainer = card.get_child(0).get_child(0)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = icon_bg
	icon_style.border_color = COLOR_OUTLINE
	icon_style.set_border_width_all(2)
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_bottom_right = 8
	icon_panel.add_theme_stylebox_override("panel", icon_style)

func _style_next_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PRIMARY
	normal.border_color = COLOR_OUTLINE
	normal.set_border_width_all(4)
	normal.corner_radius_top_left = 999
	normal.corner_radius_top_right = 999
	normal.corner_radius_bottom_left = 999
	normal.corner_radius_bottom_right = 999
	normal.shadow_color = COLOR_PRIMARY_DARK
	normal.shadow_offset = Vector2(0, 4)
	normal.shadow_size = 0

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.shadow_offset = Vector2(0, 0)

	var hover_style := normal.duplicate() as StyleBoxFlat
	hover_style.bg_color = COLOR_PRIMARY_CTR

	next_button.add_theme_stylebox_override("normal", normal)
	next_button.add_theme_stylebox_override("pressed", pressed_style)
	next_button.add_theme_stylebox_override("hover", hover_style)
	next_button.add_theme_color_override("font_color", Color.WHITE)
	next_button.add_theme_color_override("font_hover_color", Color.WHITE)
	next_button.add_theme_color_override("font_pressed_color", Color.WHITE)

# ── Save/Load Helpers ──────────────────────────

func _add_coins(amount: int) -> void:
	SaveSystem.add_coins(amount)
	SaveSystem.save_game()
	_refresh_currency_display()

func _add_egg() -> void:
	SaveSystem.add_eggs(1)
	SaveSystem.save_game()
	_refresh_currency_display()

func _refresh_currency_display() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)

# ── HUD Helpers ───────────────────────────────

func _update_hud() -> void:
	matches_label.text = "%d / %d" % [matches_done, TOTAL_PAIRS]
	turns_label.text   = "⇄ %d Turns" % turn_count
	_refresh_currency_display()

func _refresh_timer_label() -> void:
	timer_label.text = "⏱ " + _format_time(elapsed_time)

func _refresh_progress() -> void:
	var pct := float(matches_done) / float(TOTAL_PAIRS)
	# Resize the fill rect by adjusting its anchor
	progress_fill.anchor_right = pct

# ── Utility ───────────────────────────────────

func _format_time(t: float) -> String:
	var mins := int(t) / 60
	var secs := int(t) % 60
	return "%02d:%02d" % [mins, secs]

func _format_int(n: int) -> String:
	# Insert comma separators
	var s   := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out   = s[i] + out
		count += 1
	return out
