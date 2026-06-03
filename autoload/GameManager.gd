extends Node

# GameManager autoload - Central game state and screen routing.
# Navigation rules are authoritative here; UI scenes only request transitions.

# --- SIGNALS ---
signal screen_changed(screen_name: String)
signal state_changed(new_state: int, previous_state: int, extra: Dictionary)
signal debug_state_changed(debug_text: String)
signal active_monster_changed(monsterId: String)

# --- CONSTANTS ---
enum GameScreenState {
	BOOT,
	HOME,
	COLLECTION,
	MONSTER_DETAIL,
	SHOP,
	HATCH,
	REVEAL,
	MINI_GAME_HUB,
	MEMORY_GAME,
	EVOLUTION,
	SETTINGS,
}

const _STATE_LABELS: Dictionary = {
	GameScreenState.BOOT: "BOOT",
	GameScreenState.HOME: "Home",
	GameScreenState.COLLECTION: "Collection",
	GameScreenState.MONSTER_DETAIL: "MonsterDetail",
	GameScreenState.SHOP: "Shop",
	GameScreenState.HATCH: "Hatch",
	GameScreenState.REVEAL: "Reveal",
	GameScreenState.MINI_GAME_HUB: "MiniGame",
	GameScreenState.MEMORY_GAME: "MemoryGame",
	GameScreenState.EVOLUTION: "Evolution",
	GameScreenState.SETTINGS: "Settings",
}

const _LEGACY_SCREEN_NAMES: Dictionary = {
	GameScreenState.BOOT: "BOOT",
	GameScreenState.HOME: "MENU",
	GameScreenState.COLLECTION: "COLLECTION",
	GameScreenState.MONSTER_DETAIL: "CREATURE_DETAIL",
	GameScreenState.SHOP: "SHOP",
	GameScreenState.HATCH: "HATCH",
	GameScreenState.REVEAL: "REVEAL",
	GameScreenState.MINI_GAME_HUB: "MINI_GAME_HUB",
	GameScreenState.MEMORY_GAME: "MEMORY",
	GameScreenState.EVOLUTION: "EVOLUTION",
	GameScreenState.SETTINGS: "SETTINGS",
}

const _ALLOWED_TRANSITIONS: Dictionary = {
	GameScreenState.BOOT: [GameScreenState.HOME],
	GameScreenState.HOME: [
		GameScreenState.COLLECTION,
		GameScreenState.SHOP,
		GameScreenState.MINI_GAME_HUB,
		GameScreenState.EVOLUTION,
		GameScreenState.SETTINGS,
	],
	GameScreenState.COLLECTION: [
		GameScreenState.MONSTER_DETAIL,
		GameScreenState.HOME,
	],
	GameScreenState.MONSTER_DETAIL: [
		GameScreenState.COLLECTION,
		GameScreenState.EVOLUTION,
		GameScreenState.HOME,
	],
	GameScreenState.SHOP: [
		GameScreenState.HATCH,
		GameScreenState.HOME,
	],
	GameScreenState.HATCH: [
		GameScreenState.REVEAL,
	],
	GameScreenState.REVEAL: [
		GameScreenState.HOME,
	],
	GameScreenState.MINI_GAME_HUB: [
		GameScreenState.MEMORY_GAME,
		GameScreenState.HOME,
	],
	GameScreenState.MEMORY_GAME: [
		GameScreenState.HOME,
	],
	GameScreenState.EVOLUTION: [
		GameScreenState.HOME,
		GameScreenState.MONSTER_DETAIL,
	],
	GameScreenState.SETTINGS: [
		GameScreenState.HOME,
	],
}

# --- VARIABLES ---
var _active_monster_id: String = ""
var activeMonsterId: String:
	get:
		return _active_monster_id
	set(value):
		_set_active_monster_id(value)
var active_monster_id: String:
	get:
		return _active_monster_id
	set(value):
		_set_active_monster_id(value)
var selectedMonsterId: String = ""
var totalEggsHatched: int = 0
var totalCoinsEarned: int = 0
var totalMiniGamesPlayed: int = 0
var createdAt: String = ""
var current_state: GameScreenState = GameScreenState.BOOT
var previous_state: GameScreenState = GameScreenState.BOOT
var debug_mode: bool = false

var _forced_return_state: GameScreenState = GameScreenState.HOME
var _last_transition_extra: Dictionary = {}
var _last_debug_text: String = ""

# --- INITIALIZATION ---
func _ready() -> void:
	_initialize_session()
	set_debug_mode(OS.is_debug_build())
	_emit_debug_state()

func _initialize_session() -> void:
	if createdAt.is_empty():
		var datetime: Dictionary = Time.get_datetime_dict_from_system()
		createdAt = "%04d-%02d-%02dT%02d:%02d:%02d" % [
			datetime.year,
			datetime.month,
			datetime.day,
			datetime.hour,
			datetime.minute,
			datetime.second,
		]

# --- NAVIGATION ---
func change_screen(target: Variant, extra: Dictionary = {}) -> bool:
	var target_state: int = _resolve_target_state(target)
	if target_state == -1:
		push_warning("GameManager.change_screen: Unknown target %s" % str(target))
		return false

	if target_state == current_state:
		_last_transition_extra = extra.duplicate(true)
		_emit_debug_state()
		return true

	if not _is_transition_allowed(current_state, target_state):
		push_warning(
			"GameManager blocked transition %s -> %s" % [
				_STATE_LABELS.get(current_state, str(current_state)),
				_STATE_LABELS.get(target_state, str(target_state)),
			]
		)
		return false

	if target_state == GameScreenState.EVOLUTION:
		_forced_return_state = _resolve_return_state(extra, current_state)
	elif target_state == GameScreenState.HATCH:
		_forced_return_state = GameScreenState.HOME

	_transition_to(target_state, extra)
	return true

func begin_evolution_flow(origin_state: GameScreenState) -> bool:
	_forced_return_state = origin_state
	return change_screen(GameScreenState.EVOLUTION, {"return_state": origin_state})

func return_to_flow_origin(extra: Dictionary = {}) -> bool:
	return change_screen(_forced_return_state, extra)

func complete_hatch_flow() -> void:
	if current_state != GameScreenState.HATCH:
		return

	_transition_to(GameScreenState.REVEAL, {})
	await get_tree().create_timer(0.8).timeout
	change_screen(GameScreenState.HOME)

func get_current_screen_name() -> String:
	return _STATE_LABELS.get(current_state, "Unknown")

func get_debug_state_text() -> String:
	return _last_debug_text

func get_forced_return_state() -> GameScreenState:
	return _forced_return_state

func is_transition_allowed(from_state: GameScreenState, to_state: GameScreenState) -> bool:
	return _is_transition_allowed(from_state, to_state)

func _transition_to(next_state: GameScreenState, extra: Dictionary) -> void:
	previous_state = current_state
	current_state = next_state
	_last_transition_extra = extra.duplicate(true)

	_sync_legacy_navigation_state(next_state, extra)

	screen_changed.emit(_STATE_LABELS.get(next_state, "Unknown"))
	state_changed.emit(next_state, previous_state, extra)
	_emit_debug_state()

func _resolve_target_state(target: Variant) -> int:
	if target is int:
		if _STATE_LABELS.has(target):
			return target
		return -1

	var target_name: String = String(target).strip_edges()
	if target_name.is_empty():
		return -1

	match target_name.to_lower():
		"boot":
			return GameScreenState.BOOT
		"home", "menu":
			return GameScreenState.HOME
		"collection":
			return GameScreenState.COLLECTION
		"monsterdetail", "monster_detail", "creaturedetail", "creature_detail":
			return GameScreenState.MONSTER_DETAIL
		"shop":
			return GameScreenState.SHOP
		"hatch":
			return GameScreenState.HATCH
		"reveal":
			return GameScreenState.REVEAL
		"minigames", "mini_games", "minigamehub", "mini_game_hub":
			return GameScreenState.MINI_GAME_HUB
		"minigame":
			return GameScreenState.MINI_GAME_HUB
		"memorygame", "memory_game", "memory":
			return GameScreenState.MEMORY_GAME
		"evolution":
			return GameScreenState.EVOLUTION
		"settings":
			return GameScreenState.SETTINGS
		_:
			return -1

func _resolve_return_state(extra: Dictionary, fallback_state: GameScreenState) -> GameScreenState:
	var raw_return_state: Variant = extra.get("return_state", fallback_state)
	var resolved_state: int = _resolve_target_state(raw_return_state)
	if resolved_state == -1:
		return fallback_state
	return resolved_state

func _is_transition_allowed(from_state: GameScreenState, to_state: GameScreenState) -> bool:
	var allowed_states: Array = _ALLOWED_TRANSITIONS.get(from_state, [])
	return to_state in allowed_states

func _sync_legacy_navigation_state(next_state: GameScreenState, extra: Dictionary) -> void:
	if typeof(GameState) == TYPE_NIL:
		return

	match next_state:
		GameScreenState.BOOT:
			GameState.current_screen = GameState.Screen.BOOT
			GameState.screen_changed.emit(GameState.Screen.BOOT, extra)
		GameScreenState.HOME:
			GameState.current_screen = GameState.Screen.MENU
			GameState.screen_changed.emit(GameState.Screen.MENU, extra)
		GameScreenState.COLLECTION:
			GameState.current_screen = GameState.Screen.COLLECTION
			GameState.screen_changed.emit(GameState.Screen.COLLECTION, extra)
		GameScreenState.MONSTER_DETAIL:
			GameState.current_screen = GameState.Screen.CREATURE_DETAIL
			GameState.current_creature_id = extra.get("creature_id", extra.get("monster_id", GameState.current_creature_id))
			GameState.screen_changed.emit(GameState.Screen.CREATURE_DETAIL, extra)
		GameScreenState.SHOP:
			GameState.current_screen = GameState.Screen.SHOP
			GameState.screen_changed.emit(GameState.Screen.SHOP, extra)
		GameScreenState.HATCH:
			GameState.current_screen = GameState.Screen.HATCH
			GameState.screen_changed.emit(GameState.Screen.HATCH, extra)
		GameScreenState.REVEAL:
			# Transient flow state. The current scene remains active while reveal completes.
			pass
		GameScreenState.MINI_GAME_HUB:
			GameState.current_screen = GameState.Screen.MINI_GAME_HUB
			GameState.screen_changed.emit(GameState.Screen.MINI_GAME_HUB, extra)
		GameScreenState.MEMORY_GAME:
			GameState.current_screen = GameState.Screen.MEMORY
			GameState.screen_changed.emit(GameState.Screen.MEMORY, extra)
		GameScreenState.EVOLUTION:
			GameState.current_screen = GameState.Screen.EVOLUTION
			if extra.has("creature_id"):
				GameState.current_creature_id = extra.get("creature_id", "")
			GameState.screen_changed.emit(GameState.Screen.EVOLUTION, extra)
		GameScreenState.SETTINGS:
			GameState.current_screen = GameState.Screen.SETTINGS
			GameState.screen_changed.emit(GameState.Screen.SETTINGS, extra)

func _emit_debug_state() -> void:
	_last_debug_text = "Current State: %s | Allowed Transitions: %s" % [
		_STATE_LABELS.get(current_state, "Unknown"),
		_get_allowed_transition_names(current_state),
	]
	if debug_mode:
		debug_state_changed.emit(_last_debug_text)

func _get_allowed_transition_names(state: GameScreenState) -> String:
	var allowed_states: Array = _ALLOWED_TRANSITIONS.get(state, [])
	var labels: Array[String] = []
	for allowed_state in allowed_states:
		labels.append(_STATE_LABELS.get(allowed_state, str(allowed_state)))
	return ", ".join(labels)

# --- ACTIVE MONSTER MANAGEMENT ---
func set_active_monster(monsterId: String) -> void:
	if monsterId.is_empty():
		push_warning("GameManager.set_active_monster: empty monster id")
		return

	_set_active_monster_id(monsterId)
	active_monster_changed.emit(monsterId)

# --- ANALYTICS TRACKING ---
func increment_eggs_hatched() -> void:
	totalEggsHatched += 1

func increment_coins_earned(amount: int) -> void:
	if amount <= 0:
		push_warning("GameManager.increment_coins_earned: invalid amount %d" % amount)
		return

	totalCoinsEarned += amount

func increment_mini_games_played() -> void:
	totalMiniGamesPlayed += 1

# --- DEBUG MODE ---
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	_emit_debug_state()

func _set_active_monster_id(monster_id: String) -> void:
	_active_monster_id = monster_id
