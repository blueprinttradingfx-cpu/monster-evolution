extends Control

@onready var match_counter: Label = $SafeArea/VBoxContainer/TopBar/MatchCounter
@onready var pause_button: Button = $SafeArea/VBoxContainer/TopBar/PauseButton
@onready var back_button: Button = $SafeArea/VBoxContainer/TopBar/BackButton
@onready var grid_container: GridContainer = $SafeArea/VBoxContainer/GridContainer

var _card_pool: Array = []
var _card_nodes: Dictionary = {}

func _ready() -> void:
	_warm_pool()
	MemorySystem.match_success.connect(_on_match_success)
	MemorySystem.match_fail.connect(_on_match_fail)
	MemorySystem.board_completed.connect(_on_board_completed)
	pause_button.pressed.connect(_on_pause_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_start_game()

func _warm_pool() -> void:
	var card_scene: PackedScene = load("res://ui_components/card.tscn")
	for i in range(36):
		var card: Control = card_scene.instantiate()
		card.visible = false
		_card_pool.append(card)

func _start_game() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var difficulty: int = save_data["progression"]["boards_cleared"]
	var grid_size: Vector2i = MemorySystem.get_next_difficulty(difficulty)
	MemorySystem.generate_board(grid_size, "dino")
	_populate_grid()

func _populate_grid() -> void:
	for child in grid_container.get_children():
		_return_card_to_pool(child)
	
	grid_container.columns = MemorySystem.grid_size.x
	_card_nodes.clear()
	
	for y in range(MemorySystem.board.size()):
		for x in range(MemorySystem.board[y].size()):
			var card: Control = _get_card_from_pool()
			var card_data = MemorySystem.board[y][x]
			card.setup(card_data, Vector2i(x, y))
			grid_container.add_child(card)
			_card_nodes[Vector2i(x, y)] = card
	
	_update_match_counter()

func _get_card_from_pool() -> Control:
	for card in _card_pool:
		if not card.visible and card.get_parent() == null:
			card.visible = true
			return card
	var card_scene: PackedScene = load("res://ui_components/card.tscn")
	var card: Control = card_scene.instantiate()
	_card_pool.append(card)
	return card

func _return_card_to_pool(card: Control) -> void:
	if card.get_parent():
		card.get_parent().remove_child(card)
	card.reset()
	card.visible = false

func _update_match_counter() -> void:
	var total_pairs: int = (MemorySystem.grid_size.x * MemorySystem.grid_size.y) / 2
	match_counter.text = "Matches: %d/%d" % [MemorySystem.match_count, total_pairs]

func _on_match_success(pos1: Vector2i, pos2: Vector2i) -> void:
	_update_match_counter()
	if _card_nodes.has(pos1):
		_card_nodes[pos1].play_match_fx()
		_card_nodes[pos1].set_matched()
	if _card_nodes.has(pos2):
		_card_nodes[pos2].play_match_fx()
		_card_nodes[pos2].set_matched()

func _on_match_fail(pos1: Vector2i, pos2: Vector2i) -> void:
	if _card_nodes.has(pos1):
		_card_nodes[pos1].play_mismatch_fx()
		await _card_nodes[pos1].flip_to_back()
	if _card_nodes.has(pos2):
		_card_nodes[pos2].play_mismatch_fx()
		await _card_nodes[pos2].flip_to_back()

func _on_board_completed(stats: Dictionary) -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var difficulty: int = save_data["progression"]["boards_cleared"]
	RewardSystem.set_difficulty(difficulty)
	RewardSystem.process_memory_rewards(stats)
	SaveSystem.increment_progression(stats["matches"], 1)

func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)

func _on_pause_pressed() -> void:
	var pause_scene: PackedScene = load("res://scenes/overlays/pause/pause.tscn")
	NavigationManager.push_overlay(pause_scene)
