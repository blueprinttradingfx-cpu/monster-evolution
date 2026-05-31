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
@onready var top_appbar     : TopAppBar     = $TopAppBar
@onready var bottom_nav     : BottomNav     = $BottomNav
@onready var card_grid      : GridContainer = $MainLayout/ScrollContainer/ContentArea/CardGrid
@onready var matches_label  : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/MatchesPanel/MatchesContent/MatchesValue
@onready var timer_label    : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/TimerTurns/TimerLabel
@onready var turns_label    : Label         = $MainLayout/ScrollContainer/ContentArea/StatusRow/TimerTurns/TurnsLabel
@onready var progress_fill  : ColorRect     = $MainLayout/ScrollContainer/ContentArea/BonusProgressBg/BonusProgressFill
@onready var win_overlay    : CanvasLayer   = $WinOverlay
@onready var win_stats      : Label         = $WinOverlay/WinPanel/WinContent/WinStats
@onready var play_again_btn : Button        = $WinOverlay/WinPanel/WinContent/PlayAgainBtn

# ── Lifecycle ─────────────────────────────────

func _ready() -> void:
	_setup_game()
	play_again_btn.pressed.connect(_setup_game)
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
	win_stats.text = "Time: %s\nTurns: %d\n+1 🥚  +400 🪙" % [
		_format_time(elapsed_time), turn_count
	]
	win_overlay.visible = true

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
