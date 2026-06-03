extends Node

enum Screen {
	BOOT,
	SPLASH,
	TAP_TO_START,
	MENU,
	MEMORY_SETUP,
	MEMORY,
	RESULTS,
	MERGE,
	COLLECTION,
	CREATURE_DETAIL,
	SHOP,
	SETTINGS,
	DAILY_REWARD,
	HATCH,
	REVEAL,
	EVOLUTION,
	MINI_GAME_HUB,
	MEMORY_GAME,
}

signal screen_changed(new_screen: Screen, extra: Dictionary)

var current_screen: Screen = Screen.BOOT
var session_rewards: Dictionary = {}
var current_creature_id: String = ""
var merge_selected_creature_id: String = ""

func go_to(screen: Screen, extra: Dictionary = {}) -> void:
	if _should_route_via_game_manager(screen):
		if GameManager:
			GameManager.change_screen(_map_legacy_screen_to_game_manager_target(screen), extra)
			return

	current_screen = screen
	if screen == Screen.CREATURE_DETAIL:
		current_creature_id = extra.get("creature_id", "")
	elif screen == Screen.MERGE:
		merge_selected_creature_id = extra.get("creature_id", "")
	screen_changed.emit(screen, extra)

func _should_route_via_game_manager(screen: Screen) -> bool:
	match screen:
		Screen.MENU, Screen.COLLECTION, Screen.CREATURE_DETAIL, Screen.SHOP, Screen.SETTINGS, Screen.HATCH, Screen.REVEAL, Screen.EVOLUTION, Screen.MINI_GAME_HUB, Screen.MEMORY_GAME:
			return true
		_:
			return false

func _map_legacy_screen_to_game_manager_target(screen: Screen) -> String:
	match screen:
		Screen.MENU:
			return "Home"
		Screen.COLLECTION:
			return "Collection"
		Screen.CREATURE_DETAIL:
			return "MonsterDetail"
		Screen.SHOP:
			return "Shop"
		Screen.SETTINGS:
			return "Settings"
		Screen.HATCH:
			return "Hatch"
		Screen.REVEAL:
			return "Reveal"
		Screen.EVOLUTION:
			return "Evolution"
		Screen.MINI_GAME_HUB:
			return "MiniGame"
		Screen.MEMORY_GAME:
			return "MemoryGame"
		_:
			return "Home"
