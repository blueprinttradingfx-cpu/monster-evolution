extends Control

# ─────────────────────────────────────────────
#  Merge Memory Monsters — Game Script (Godot 4)
#  Converted from HTML/Tailwind UI prototype
# ─────────────────────────────────────────────

# ── Tuning ────────────────────────────────────
const FLIP_DURATION    := 0.25   # seconds for half-flip
const FLIP_WAIT        := 0.8    # seconds before hiding unmatched pair

# Level configurations: [rows, cols, pairs, monsters_needed, card_size]
const LEVELS := [
	[2, 2, 2, 2, Vector2(180, 280)],  # Level 1: 2x2 grid, 2 pairs, 2 monster types, large cards
	[2, 3, 3, 3, Vector2(180, 280)],  # Level 2: 2x3 grid, 3 pairs, 3 monster types, medium-large cards
	[2, 4, 4, 4, Vector2(180, 280)],  # Level 3: 2x4 grid, 4 pairs, 4 monster types, medium cards
	[3, 4, 6, 6, Vector2(180, 280)],  # Level 4: 3x4 grid, 6 pairs, 6 monster types, medium-small cards
	[4, 4, 8, 8, Vector2(180, 280)],   # Level 5: 4x4 grid, 8 pairs, 8 monster types, small cards
]

# Monster emoji used as card faces (one per pair)
const MONSTERS := ["🟢","🔵","🟣","🟡","🔴","🟠","⚪","🟤"]

# ── State ─────────────────────────────────────
var current_level : int = 1
var matches_done : int  = 0
var turn_count   : int  = 0
var elapsed_time : float = 0.0
var is_timing    : bool  = true

var card_values: Array[int] = []   # assigned monster index per card slot
var card_matched: Array[bool] = []   # permanently revealed
var flipped_now: Array[int] = []   # indices of currently face-up (unmatched) cards
var is_locked: bool = false       # prevent clicks during flip-back animation
var grid_pos_to_idx: Dictionary = {}  # maps Vector2i grid pos to idx
var grid_cols: int = 0

var _card_scene = preload("res://ui_components/card.tscn")

# Node references (resolved in _ready)
@onready var top_appbar        : Control     = $RootLayout/TopAppBar
@onready var bottom_nav        : Control     = $RootLayout/BottomNav
@onready var card_grid : GridContainer = $RootLayout/ScrollContainer/SafeArea/Main/BoardGridContainer/CenterContainer/CardGrid
@onready var level_label       : Label         = $RootLayout/ScrollContainer/SafeArea/Main/MatchesPanel/MatchesContent/LevelLabel
@onready var matches_label     : Label         = $RootLayout/ScrollContainer/SafeArea/Main/MatchesPanel/MatchesContent/MatchesValue
@onready var timer_label       : Label         = $RootLayout/ScrollContainer/SafeArea/Main/TimerTurns/TimerLabel
@onready var turns_label       : Label         = $RootLayout/ScrollContainer/SafeArea/Main/TimerTurns/TurnsLabel
@onready var progress_fill     : ColorRect     = $RootLayout/ScrollContainer/SafeArea/Main/BonusProgressBg/BonusProgressFill
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
	# Load saved level
	current_level = GameManager.totalMiniGamesPlayed + 1 if GameManager else 1
	_setup_game()
	next_button.pressed.connect(_setup_game)
	confetti_timer.timeout.connect(_spawn_confetti_burst)
	_update_hud()
	_connect_bottom_nav()
	bottom_nav.set_active("Home")
	
	# Increment total mini games played
	if GameManager:
		GameManager.totalMiniGamesPlayed += 1
		if SaveManager:
			SaveManager.save_game()
	
	# Set all label font sizes to 24px
	level_label.add_theme_font_size_override("font_size", 24)
	matches_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_font_size_override("font_size", 24)
	turns_label.add_theme_font_size_override("font_size", 24)
	egg_value_label.add_theme_font_size_override("font_size", 24)
	coin_value_label.add_theme_font_size_override("font_size", 24)
	progress_pct.add_theme_font_size_override("font_size", 24)

func _process(delta: float) -> void:
	if is_timing:
		elapsed_time += delta
		_refresh_timer_label()

# ── Bottom Nav Connection ─────────────────────

func _connect_bottom_nav() -> void:
	bottom_nav.tab_changed.connect(_on_tab_pressed)

func _on_tab_pressed(tab_name: String):
	bottom_nav.set_active(tab_name)
	if GameManager:
		GameManager.change_screen(tab_name)

# ── Game Setup ────────────────────────────────

func _setup_game() -> void:
	# Get level configuration
	var level_idx: int = clamp(current_level - 1, 0, LEVELS.size() - 1)
	var level_config: Array = LEVELS[level_idx]
	var grid_rows: int = level_config[0]
	var grid_cols: int = level_config[1]
	var total_pairs: int = level_config[2]
	var monsters_needed: int = level_config[3]
	var card_size: Vector2 = level_config[4]

	# Store grid cols for position calculation
	self.grid_cols = grid_cols

	# Update grid columns and separation
	card_grid.columns = grid_cols
	var separation: int = int(card_size.x * 0.1)
	card_grid.add_theme_constant_override("h_separation", separation)
	card_grid.add_theme_constant_override("v_separation", separation)

	# Reset state
	matches_done = 0
	turn_count = 0
	elapsed_time = 0.0
	is_timing = true
	is_locked = false
	flipped_now.clear()
	win_overlay.visible = false
	confetti_timer.stop()
	grid_pos_to_idx.clear()

	# Clear any remaining confetti
	for child in confetti_layer.get_children():
		child.queue_free()

	# Build & shuffle card values
	card_values.clear()
	card_matched.clear()
	for i in total_pairs:
		card_values.append(i)
		card_values.append(i)
	card_values.shuffle()
	for i in card_values.size():
		card_matched.append(false)

	# Build grid
	# Clear existing children first
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		# Disconnect the signal before returning/freeing
		var btn = child as Button
		if btn:
			if btn.card_pressed.is_connected(_on_card_pressed):
				btn.card_pressed.disconnect(_on_card_pressed)
			# Reset card state
			if btn.has_method("reset"):
				btn.reset()
		if has_node("/root/PerformanceLayer"):
			get_node("/root/PerformanceLayer").return_to_pool("card", child)
		else:
			child.queue_free()

	for idx in card_values.size():
		var card := _make_card(idx, card_size)
		if card:
			card_grid.add_child(card)

	_log_card_status()  # Log all card details on game start
	# Update HUD and progress
	_update_hud()
	_refresh_progress(total_pairs)

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)

# ── Card Factory ──────────────────────────────

func _make_card(idx: int, card_size: Vector2) -> Button:
	var card: Button
	if has_node("/root/PerformanceLayer"):
		card = get_node("/root/PerformanceLayer").get_from_pool("card", _card_scene) as Button
	else:
		card = _card_scene.instantiate() as Button

	if not card:
		return null

	card.custom_minimum_size = card_size
	card.name = "Card_%d" % idx

	# Setup the new card with our card.gd script
	var x = idx % grid_cols
	var y = idx / grid_cols
	var grid_pos = Vector2i(x, y)
	if card.has_method("setup"):
		# Create a dummy card data object for our new card
		var dummy_card_data: Dictionary = { "id": idx }
		card.setup(dummy_card_data, grid_pos)
	
	# Set the monster text on the FrontFace NOW, not just when flipping up
	var front_face = card.get_node_or_null("FrontFace")
	if front_face:
		var monster_label = front_face.get_node_or_null("MonsterLabel")
		if monster_label:
			var monster_idx: int = card_values[idx]
			monster_label.text = MONSTERS[monster_idx]
			monster_label.theme_type_variation = ""
			monster_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Also ensure BackFace is properly styled
	var back_face = card.get_node_or_null("BackFace") as Label
	if back_face:
		back_face.theme_type_variation = ""
		back_face.add_theme_color_override("font_color", Color.BLACK)
		back_face.add_theme_font_size_override("font_size", 1)

	# Store mapping of grid_pos to idx
	grid_pos_to_idx[grid_pos] = idx

	# Connect our own logic
	if card.card_pressed.is_connected(_on_card_pressed):
		card.card_pressed.disconnect(_on_card_pressed)
	card.card_pressed.connect(_on_card_pressed)

	return card

# ── Input Handling ────────────────────────────

func _on_card_pressed(grid_pos: Vector2i) -> void:
	var idx = grid_pos_to_idx.get(grid_pos, -1)
	if idx == -1:
		return
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

	_emit_juice("card_flip", {"node": card_grid.get_child(idx)})

	if flipped_now.size() == 2:
		turn_count += 1
		_check_match()

# ── Flip Animations ───────────────────────────

func _flip_card_up(idx: int) -> void:
	var card: Button = card_grid.get_child(idx) as Button
	if not card:
		return

	# Update FrontFace to show the monster emoji
	var front_face = card.get_node_or_null("FrontFace")
	if front_face:
		var monster_label = front_face.get_node_or_null("MonsterLabel")
		if monster_label:
			var monster_idx: int = card_values[idx]
			monster_label.text = MONSTERS[monster_idx]
			monster_label.theme_type_variation = ""
			monster_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Also make sure BackFace is visible/colored
	var back_face: Label = card.get_node("BackFace") as Label
	if back_face:
		back_face.theme_type_variation = ""
		back_face.add_theme_color_override("font_color", Color.BLACK)

	if card.has_method("flip_to_front"):
		card.flip_to_front()

func _flip_card_down(idx: int) -> void:
	var card: Button = card_grid.get_child(idx) as Button
	if not card:
		return

	if card.has_method("flip_to_back"):
		card.flip_to_back()

func _mark_card_matched(idx: int) -> void:
	var card: Button = card_grid.get_child(idx) as Button
	if not card:
		return

	if card.has_method("set_matched"):
		card.set_matched()

	if card.has_method("lock"):
		card.lock()

# ── Match Logic ───────────────────────────────

func _check_match() -> void:
	print("=== CHECKING MATCH ===")
	print("  flipped_now: %s" % str(flipped_now))
	is_locked = true
	var a := flipped_now[0]
	var b := flipped_now[1]
	print("  a: %d, b: %d" % [a, b])
	print("  card_values[a]: %s, card_values[b]: %s" % [MONSTERS[card_values[a]], MONSTERS[card_values[b]]])

	if card_values[a] == card_values[b]:
		print("  → MATCH FOUND!")
		# Match found!
		card_matched[a] = true
		card_matched[b] = true
		_mark_card_matched(a)
		_mark_card_matched(b)
		matches_done += 1
		_add_coins(25)
		_emit_juice("match_success", {"a_node": card_grid.get_child(a), "b_node": card_grid.get_child(b)})

		flipped_now.clear()
		is_locked = false
		_update_hud()

		# Get current level total pairs
		var level_idx: int = clamp(current_level - 1, 0, LEVELS.size() - 1)
		var total_pairs: int = LEVELS[level_idx][2]
		_refresh_progress(total_pairs)

		if matches_done == total_pairs:
			_on_win()
	else:
		print("  → NO MATCH, flipping back...")
		# No match — wait, then flip back
		_emit_juice("match_fail", {"a_node": card_grid.get_child(a), "b_node": card_grid.get_child(b)})
		print("  Waiting for %f seconds..." % FLIP_WAIT)
		await get_tree().create_timer(FLIP_WAIT).timeout
		print("  Calling _flip_card_down on %d and %d..." % [a, b])
		_flip_card_down(a)
		_flip_card_down(b)
		flipped_now.clear()
		is_locked = false

# ── Win Condition ─────────────────────────────

func _on_win() -> void:
	is_timing = false
	_emit_juice("board_complete", {"level": current_level})
	_add_egg()
	_add_coins(200)
	_update_hud()

	# Update overlay reward labels
	egg_value_label.text = "+1 Egg"
	coin_value_label.text = "+200 Coins"

	# Animate progress bar
	var progress_target: float = 1.0
	progress_bar_fill.size.x = 0.0
	progress_pct.text = "100%"
	var tween: Tween = create_tween()
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

	# Progress to next level (cap at max level) and save!
	if current_level < LEVELS.size():
		current_level += 1
		if SaveManager:
			SaveManager.save_game()

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
		var c: ColorRect = ColorRect.new()
		c.size = Vector2(8, 8)
		c.color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
		c.position = Vector2(randf() * viewport_size.x, -20.0)
		confetti_layer.add_child(c)

		var duration: float = randf_range(2.0, 4.0)
		var rot_deg: float = randf_range(0.0, 720.0)
		var tween: Tween = create_tween()
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
	var egg_card: Node = win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/RewardCards/EggCard")
	var coin_card: Node = win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/RewardCards/CoinCard")
	_style_reward_card(egg_card as PanelContainer, COLOR_EGG_YELLOW)
	_style_reward_card(coin_card as PanelContainer, COLOR_COIN_GOLD)

	# Progress bar background
	var prog_bg: Node = win_control.get_node("WinMainLayout/WinCenterContainer/WinContent/EvolutionSection/ProgressBarBG")
	var prog_bg_style: StyleBoxFlat = StyleBoxFlat.new()
	prog_bg_style.bg_color = COLOR_SURF_SOFT
	prog_bg_style.border_color = COLOR_OUTLINE
	prog_bg_style.set_border_width_all(4)
	prog_bg_style.corner_radius_top_left = 32
	prog_bg_style.corner_radius_top_right = 32
	prog_bg_style.corner_radius_bottom_left = 32
	prog_bg_style.corner_radius_bottom_right = 32
	(prog_bg as PanelContainer).add_theme_stylebox_override("panel", prog_bg_style)

	# Progress bar fill color
	progress_bar_fill.color = COLOR_GREEN

	# Next button
	_style_next_button()

func _style_reward_card(card: PanelContainer, icon_bg: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
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
	var icon_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_style.bg_color = icon_bg
	icon_style.border_color = COLOR_OUTLINE
	icon_style.set_border_width_all(2)
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_bottom_right = 8
	icon_panel.add_theme_stylebox_override("panel", icon_style)

func _style_next_button() -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
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

	var pressed_style: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed_style.shadow_offset = Vector2(0, 0)

	var hover_style: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover_style.bg_color = COLOR_PRIMARY_CTR

	next_button.add_theme_stylebox_override("normal", normal)
	next_button.add_theme_stylebox_override("pressed", pressed_style)
	next_button.add_theme_stylebox_override("hover", hover_style)
	next_button.add_theme_color_override("font_color", Color.WHITE)
	next_button.add_theme_color_override("font_hover_color", Color.WHITE)
	next_button.add_theme_color_override("font_pressed_color", Color.WHITE)

# ── Save/Load Helpers ──────────────────────────

func _add_coins(amount: int) -> void:
	if EconomyManager:
		EconomyManager.add_coins(amount)
	if GameManager:
		GameManager.totalCoinsEarned += amount
	if SaveManager:
		SaveManager.save_game()
	_refresh_currency_display()

func _add_egg() -> void:
	if MonsterManager:
		var new_egg_id: String = "egg_" + str(Time.get_ticks_msec())
		MonsterManager.add_egg(new_egg_id, "dino_egg")
	if SaveManager:
		SaveManager.save_game()
	_refresh_currency_display()

func _refresh_currency_display() -> void:
	var coins: int = EconomyManager.get_coins() if EconomyManager else 0
	var eggs_count: int = MonsterManager.get_owned_egg_count() if MonsterManager else 0
	if top_appbar:
		if top_appbar.has_method("set_coins"):
			top_appbar.set_coins(coins)
		if top_appbar.has_method("set_eggs"):
			top_appbar.set_eggs(eggs_count)

# ── HUD Helpers ───────────────────────────────

func _update_hud() -> void:
	var level_idx: int = clamp(current_level - 1, 0, LEVELS.size() - 1)
	var total_pairs: int = LEVELS[level_idx][2]
	level_label.text = "LEVEL %d" % current_level
	matches_label.text = "%d / %d" % [matches_done, total_pairs]
	turns_label.text   = "⇄ %d Turns" % turn_count
	_refresh_currency_display()

func _refresh_timer_label() -> void:
	timer_label.text = "⏱ " + _format_time(elapsed_time)

func _refresh_progress(total_pairs: int) -> void:
	var pct: float = float(matches_done) / float(total_pairs)
	# Resize the fill rect by adjusting its anchor
	progress_fill.anchor_right = pct

# ── Utility: Log Card Status ─────────────────────────────
func _log_card_status(clicked_idx: int = -1) -> void:
	print("=== CARD STATUS ===")
	for idx in card_values.size():
		var grid_pos: Vector2i
		# Find grid_pos from idx (reverse lookup of grid_pos_to_idx)
		for pos in grid_pos_to_idx:
			if grid_pos_to_idx[pos] == idx:
				grid_pos = pos
				break
		
		var card = card_grid.get_child(idx) as Button
		if card:
			var prefix = "→ " if idx == clicked_idx else "  "
			print("%sCard %d (Grid: %s):" % [prefix, idx, str(grid_pos)])
			print("  Value: %s" % MONSTERS[card_values[idx]])
			print("  Flipped: %s" % str(card.is_flipped() if card.has_method("is_flipped") else false))
			print("  Matched: %s" % str(card_matched[idx]))
			print("  Disabled: %s" % str(card.disabled))
			print("  Modulate: %s" % str(card.modulate))
			# Log background states
			var bg_node = card.get_node_or_null("Bg")
			if bg_node:
				print("  Bg visible: %s" % str(bg_node.visible))
			var flipped_bg_node = card.get_node_or_null("FlippedBg")
			if flipped_bg_node:
				print("  FlippedBg visible: %s, color: %s" % [str(flipped_bg_node.visible), str(flipped_bg_node.color)])
			# Log text nodes
			var back_face = card.get_node_or_null("BackFace")
			if back_face:
				print("  BackFace visible: %s, text: '%s'" % [str(back_face.visible), back_face.text])
			var front_face = card.get_node_or_null("FrontFace")
			if front_face:
				if front_face is Label:
					print("  FrontFace visible: %s, text: '%s'" % [str(front_face.visible), front_face.text])
				elif front_face is TextureRect:
					print("  FrontFace visible: %s, texture: '%s'" % [str(front_face.visible), front_face.texture.resource_path if front_face.texture else "null"])
				else:
					print("  FrontFace visible: %s, type: %s" % [str(front_face.visible), front_face.get_class()])

# ── Utility ───────────────────────────────────

func _format_time(t: float) -> String:
	var mins: int = int(t) / 60
	var secs: int = int(t) % 60
	return "%02d:%02d" % [mins, secs]

func _format_int(n: int) -> String:
	# Insert comma separators
	var s: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out   = s[i] + out
		count += 1
	return out
