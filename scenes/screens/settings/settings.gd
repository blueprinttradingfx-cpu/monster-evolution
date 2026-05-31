extends Control

@onready var top_appbar: TopAppBar = $TopAppBar
@onready var bottom_nav: BottomNav = $BottomNav

@onready var sound_toggle: CheckButton = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/SoundCard/SoundHBox/SoundToggle
@onready var music_toggle: CheckButton = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/MusicCard/MusicHBox/MusicToggle
@onready var lang_sub_label: Label = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/LanguageCard/LanguageHBox/LangTextVBox/LangSubLabel
@onready var lang_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/LanguageCard/LanguageHBox/LangButton
@onready var reset_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/ResetSection/ResetButton
@onready var close_button: Button = $MainLayout/ScrollContainer/ContentVBox/SideMargin/CardsVBox/CloseSection/CloseButton
@onready var reset_dialog: ConfirmationDialog = $ResetConfirmDialog

const LANGUAGES: Array[Dictionary] = [
	{"code": "EN", "name": "English"},
	{"code": "ES", "name": "Español"},
	{"code": "JP", "name": "日本語"},
	{"code": "FR", "name": "Français"},
	{"code": "DE", "name": "Deutsch"},
]

var _current_lang_index: int = 0

const SAVE_KEY_SOUND = "settings/sound_enabled"
const SAVE_KEY_MUSIC = "settings/music_enabled"
const SAVE_KEY_LANG  = "settings/language_index"

func _ready():
	_load_settings()
	_connect_signals()
	_refresh_currency_display()
	bottom_nav.set_active("settings")
	bottom_nav.start_button.visible = false

func _connect_signals():
	sound_toggle.toggled.connect(_on_sound_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	lang_button.pressed.connect(_on_language_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	bottom_nav.tab_changed.connect(_on_tab_pressed)

func _refresh_currency_display():
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)

func _on_sound_toggled(pressed: bool):
	_save_setting(SAVE_KEY_SOUND, pressed)
	print("Sound ", "ON" if pressed else "OFF")

func _on_music_toggled(pressed: bool):
	_save_setting(SAVE_KEY_MUSIC, pressed)
	print("Music ", "ON" if pressed else "OFF")

func _on_language_pressed():
	_current_lang_index = (_current_lang_index + 1) % LANGUAGES.size()
	_update_language_ui()
	_save_setting(SAVE_KEY_LANG, _current_lang_index)

func _update_language_ui():
	var lang: Dictionary = LANGUAGES[_current_lang_index]
	lang_button.text = lang["code"]
	lang_sub_label.text = "Selected: " + lang["name"]

func _on_reset_pressed():
	reset_dialog.popup_centered()

func _on_reset_confirmed():
	print("Progress RESET confirmed.")
	SaveSystem.reset_save()
	_refresh_currency_display()

func _on_close_pressed():
	GameState.go_to(GameState.Screen.MENU)

func _on_tab_pressed(tab: String):
	match tab:
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

func _save_setting(key: String, value: Variant):
	SaveSystem.set_setting(key, value)
	SaveSystem.save_game()

func _load_settings():
	var save_data: Dictionary = SaveSystem.get_data()
	var settings: Dictionary = save_data.get("settings", {})
	
	var sound_on: bool = settings.get(SAVE_KEY_SOUND, true)
	sound_toggle.button_pressed = sound_on
	
	var music_on: bool = settings.get(SAVE_KEY_MUSIC, true)
	music_toggle.button_pressed = music_on
	
	if settings.has(SAVE_KEY_LANG):
		_current_lang_index = settings[SAVE_KEY_LANG]
		_current_lang_index = clamp(_current_lang_index, 0, LANGUAGES.size() - 1)
		_update_language_ui()
