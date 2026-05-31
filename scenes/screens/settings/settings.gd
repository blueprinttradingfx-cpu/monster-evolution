extends Control

@onready var sound_toggle_button: Button = $SafeArea/VBoxContainer/SoundRow/SoundToggleButton
@onready var music_toggle_button: Button = $SafeArea/VBoxContainer/MusicRow/MusicToggleButton
@onready var reset_button: Button = $SafeArea/VBoxContainer/ResetButton
@onready var close_button: Button = $SafeArea/VBoxContainer/CloseButton

func _ready() -> void:
	sound_toggle_button.pressed.connect(_on_sound_toggle)
	music_toggle_button.pressed.connect(_on_music_toggle)
	reset_button.pressed.connect(_on_reset)
	close_button.pressed.connect(_on_close_pressed)
	
	_update_ui()

func _update_ui() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var sound_on: bool = save_data["settings"].get("sfx_volume", 1.0) > 0.0
	var music_on: bool = save_data["settings"].get("music_volume", 1.0) > 0.0
	sound_toggle_button.text = "ON" if sound_on else "OFF"
	music_toggle_button.text = "ON" if music_on else "OFF"

func _on_sound_toggle() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var new_volume: float = 0.0 if save_data["settings"]["sfx_volume"] > 0.0 else 1.0
	SaveSystem.set_setting("sfx_volume", new_volume)
	SaveSystem.save_game()
	_update_ui()

func _on_music_toggle() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var new_volume: float = 0.0 if save_data["settings"]["music_volume"] > 0.0 else 1.0
	SaveSystem.set_setting("music_volume", new_volume)
	SaveSystem.save_game()
	_update_ui()

func _on_reset() -> void:
	# For MVP, just do a quick reset - in full game you'd ask for confirmation
	var save_data: Dictionary = SaveSystem.get_data()
	save_data["economy"]["coins"] = 0
	save_data["inventory"] = ["egg", "egg"]
	save_data["progression"]["total_matches"] = 0
	save_data["progression"]["boards_cleared"] = 0
	save_data["daily"]["streak"] = 0
	save_data["daily"]["last_login_date"] = ""
	save_data["daily"]["claimed"] = false
	SaveSystem.save_game()
	GameState.go_to(GameState.Screen.TAP_TO_START)

func _on_close_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)
