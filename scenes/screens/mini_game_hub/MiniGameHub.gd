extends Control

# --- SIGNALS ---
signal mini_game_selected(game_id: String)

# --- NODES ---
@onready var _top_app_bar: Control = $RootLayout/TopAppBar
@onready var _bottom_nav: BottomNav = $RootLayout/BottomNav
@onready var _game_list: VBoxContainer = $RootLayout/ScrollContainer/SafeArea/MainContent/GameList
@onready var _empty_label: Label = $RootLayout/ScrollContainer/SafeArea/MainContent/EmptyLabel

# --- CONSTANTS ---
const AVAILABLE_GAMES: Array[Dictionary] = [
	{
		"id": "memory_match",
		"name": "Memory Match",
		"icon": "",
		"difficulty": "Easy",
		"reward_range": "10 - 50 coins",
		"unlocked": true
	},
	{
		"id": "future_game_1",
		"name": "Coming Soon...",
		"icon": "",
		"difficulty": "",
		"reward_range": "",
		"unlocked": false
	},
	{
		"id": "future_game_2",
		"name": "Coming Soon...",
		"icon": "",
		"difficulty": "",
		"reward_range": "",
		"unlocked": false
	}
]

func _ready() -> void:
	_refresh_game_list()
	if _bottom_nav and _bottom_nav.has_method("set_active"):
		_bottom_nav.set_active("Home") # Home tab is the active one for MiniGameHub

func _refresh_game_list() -> void:
	# Clear existing children
	for child in _game_list.get_children():
		child.queue_free()
	
	var has_available_games: bool = false
	for game in AVAILABLE_GAMES:
		if game.unlocked:
			has_available_games = true
		_add_game_card(game)
	
	_empty_label.visible = not has_available_games

func _add_game_card(game: Dictionary) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 200)
	card.layout_mode = 2
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.layout_mode = 2
	card.add_child(vbox)
	
	var name_label: Label = Label.new()
	name_label.text = str(game.get("name", "Unnamed Game"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_type_variation = "HeaderMedium"
	vbox.add_child(name_label)
	
	var difficulty_label: Label = Label.new()
	var difficulty_text: String = str(game.get("difficulty", ""))
	difficulty_label.text = "Difficulty: %s" % (difficulty_text if not difficulty_text.is_empty() else "TBD")
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(difficulty_label)
	
	var reward_label: Label = Label.new()
	var reward_text: String = str(game.get("reward_range", ""))
	reward_label.text = "Rewards: %s" % (reward_text if not reward_text.is_empty() else "TBD")
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_label)
	
	var play_button: Button = Button.new()
	var is_unlocked: bool = bool(game.get("unlocked", false))
	play_button.text = "Play" if is_unlocked else "Locked"
	play_button.disabled = not is_unlocked
	play_button.custom_minimum_size = Vector2(200, 60)
	vbox.add_child(play_button)
	
	if is_unlocked:
		play_button.pressed.connect(func(): _on_game_play_pressed(str(game.get("id", ""))))
	
	_game_list.add_child(card)

func _on_game_play_pressed(game_id: String) -> void:
	print("Game selected: %s" % game_id)
	mini_game_selected.emit(game_id)
	if game_id == "memory_match":
		if GameState:
			GameState.go_to(GameState.Screen.MEMORY)
