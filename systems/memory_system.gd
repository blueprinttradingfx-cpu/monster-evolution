extends Node

enum CardState {
	HIDDEN,
	FLIPPED,
	MATCHED
}

class CardData:
	var id: String
	var state: int
	var position: Vector2i

	func _init(_id: String, _pos: Vector2i):
		id = _id
		state = CardState.HIDDEN
		position = _pos

signal board_generated(board_data: Array)
signal match_success(a: Vector2i, b: Vector2i)
signal card_matched(a: Vector2i, b: Vector2i)
signal match_fail(a: Vector2i, b: Vector2i)
signal card_mismatch(a: Vector2i, b: Vector2i)
signal board_completed(stats: Dictionary)

var board: Array = []
var flipped_cards: Array[Vector2i] = []

var balancing_config: Resource = preload("res://resources/balancing/game_balancing.tres")

var grid_size: Vector2i = Vector2i(2, 2)
var move_count: int = 0
var match_count: int = 0
var start_time: float = 0.0
var input_locked: bool = false

func _ready() -> void:
	pass

func get_total_cells(grid: Vector2i) -> int:
	return grid.x * grid.y

func build_pairs(pair_count: int, theme_cards: Array[String]) -> Array[String]:
	var pairs: Array[String] = []
	for i in range(pair_count):
		var base_id: String = theme_cards[i % theme_cards.size()]
		pairs.append(base_id)
		pairs.append(base_id)
	return pairs

func shuffle_deck(deck: Array[String]) -> Array[String]:
	deck.shuffle()
	return deck

func build_board(deck: Array[String], grid: Vector2i) -> Array:
	var new_board: Array = []
	var index: int = 0
	for y in range(grid.y):
		var row: Array = []
		for x in range(grid.x):
			var card: CardData = CardData.new(deck[index], Vector2i(x, y))
			row.append(card)
			index += 1
		new_board.append(row)
	return new_board

func generate_board(size: Vector2i, theme: String) -> void:
	if has_node("/root/DebugTuner"):
		var debug_tuner = get_node("/root/DebugTuner")
		size = debug_tuner.get_grid_size(size)

	if has_node("/root/TutorialSystem") and get_node("/root/TutorialSystem").is_active and get_node("/root/TutorialSystem").current_step <= 1:
		size = Vector2i(2, 2) # Force 2x2 for tutorial

	grid_size = size
	var total: int = get_total_cells(size)
	if total % 2 != 0:
		push_error("Board must have even number of cells")
		return

	var pair_count: int = total / 2
	var theme_cards: Array[String] = _get_theme_cards(theme)
	var deck: Array[String] = build_pairs(pair_count, theme_cards)
	deck = shuffle_deck(deck)
	board = build_board(deck, size)

	flipped_cards.clear()
	move_count = 0
	match_count = 0
	start_time = Time.get_ticks_msec() / 1000.0
	input_locked = false
	emit_signal("board_generated", board)

func _emit_juice(event_type: String, payload: Dictionary) -> void:
	var juice_layer = get_node_or_null("/root/UIJuiceLayer")
	if juice_layer:
		juice_layer.on_event(event_type, payload)

func flip_card(pos: Vector2i) -> void:
	if input_locked:
		return
	var card: CardData = board[pos.y][pos.x]
	if card.state == CardState.MATCHED:
		return
	if card.state == CardState.FLIPPED:
		return
	if flipped_cards.size() >= 2:
		return

	card.state = CardState.FLIPPED
	flipped_cards.append(pos)
	_emit_juice("card_flip", {"pos": pos})

	if flipped_cards.size() == 2:
		check_match()

func check_match() -> void:
	move_count += 1
	input_locked = true
	var a: Vector2i = flipped_cards[0]
	var b: Vector2i = flipped_cards[1]
	var card_a: CardData = board[a.y][a.x]
	var card_b: CardData = board[b.y][b.x]

	if card_a.id == card_b.id:
		handle_match(a, b)
	else:
		handle_mismatch(a, b)

	flipped_cards.clear()

func handle_match(a: Vector2i, b: Vector2i) -> void:
	board[a.y][a.x].state = CardState.MATCHED
	board[b.y][b.x].state = CardState.MATCHED
	match_count += 1

	emit_signal("match_success", a, b)
	emit_signal("card_matched", a, b)
	_emit_juice("match_success", {"a": a, "b": b})

	if has_node("/root/TutorialSystem") and get_node("/root/TutorialSystem").is_active and get_node("/root/TutorialSystem").current_step == 1:
		get_node("/root/TutorialSystem").next_step()

	if is_board_cleared():
		_finish_board()

	input_locked = false

func handle_mismatch(a: Vector2i, b: Vector2i) -> void:
	emit_signal("match_fail", a, b)
	emit_signal("card_mismatch", a, b)
	_emit_juice("match_fail", {"a": a, "b": b})

	await get_tree().create_timer(0.6).timeout

	board[a.y][a.x].state = CardState.HIDDEN
	board[b.y][b.x].state = CardState.HIDDEN
	input_locked = false

func is_board_cleared() -> bool:
	for row in board:
		for card in row:
			if card.state != CardState.MATCHED:
				return false
	return true

func _finish_board() -> void:
	var duration: float = (Time.get_ticks_msec() / 1000.0) - start_time
	var stats: Dictionary = {
		"moves": move_count,
		"matches": match_count,
		"time": duration,
		"grid": grid_size
	}
	emit_signal("board_completed", stats)
	_emit_juice("board_complete", stats)

func get_current_difficulty() -> Vector2i:
	var boards_cleared = 0
	var save_data = SaveSystem.get_data()
	if save_data.has("progression") and save_data["progression"].has("boards_cleared"):
		boards_cleared = save_data["progression"]["boards_cleared"]

	return get_next_difficulty(boards_cleared)

func get_next_difficulty(current_level: int) -> Vector2i:
	if balancing_config:
		return balancing_config.get_grid_for_level(current_level)

	# Fallback if config is missing
	match current_level:
		0:
			return Vector2i(2, 2)
		1:
			return Vector2i(2, 3)
		2:
			return Vector2i(4, 2)
		3:
			return Vector2i(4, 4)
		4:
			return Vector2i(4, 5)
		_:
			return Vector2i(6, 6)

func _get_theme_cards(theme: String) -> Array[String]:
	match theme:
		"dino":
			return ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
		"animals":
			return ["cat", "dog", "fox", "bear", "wolf", "lion"]
		"space":
			return ["planet", "star", "rocket", "alien", "blackhole"]
		_:
			return ["a", "b", "c", "d", "e", "f"]
