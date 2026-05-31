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
	SETTINGS
}

signal screen_changed(new_screen: Screen, extra: Dictionary)

var current_screen: Screen = Screen.BOOT
var session_rewards: Dictionary = {}
var current_creature_id: String = ""  # Used for CREATURE_DETAIL

func go_to(screen: Screen, extra: Dictionary = {}) -> void:
	current_screen = screen
	if screen == Screen.CREATURE_DETAIL:
		current_creature_id = extra.get("creature_id", "")
	screen_changed.emit(screen, extra)
