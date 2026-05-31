extends Control

@onready var creature: TextureRect = $SafeArea/Main/CreatureSection/CreatureWrapper/Creature
@onready var bar_fill: ColorRect = $SafeArea/Main/CreatureSection/ProgressSection/EvolutionBar/BarFill
@onready var sparkle: ColorRect = $SafeArea/Main/CreatureSection/ProgressSection/EvolutionBar/BarFill/Sparkle
@onready var play_button: Button = $SafeArea/Main/ActionButtons/PlayButton
@onready var merge_button: Button = $SafeArea/Main/ActionButtons/GridButtons/MergeButton
@onready var collection_button: Button = $SafeArea/Main/ActionButtons/GridButtons/CollectionButton
@onready var top_appbar: TopAppBar = $TopAppBar
@onready var progress_title: Label = $SafeArea/Main/CreatureSection/ProgressSection/ProgressHeader/ProgressTitle
@onready var progress_value: Label = $SafeArea/Main/CreatureSection/ProgressSection/ProgressHeader/ProgressValue
@onready var bottom_nav: BottomNav = $BottomNav

func _ready() -> void:
	_play_intro_animation()
	play_button.pressed.connect(_on_play_pressed)
	merge_button.pressed.connect(_on_merge_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.start_pressed.connect(_on_play_pressed)
	bottom_nav.set_active("play")
	bottom_nav.start_button.visible = true
	if SaveSystem.check_daily_reward():
		GameState.go_to(GameState.Screen.DAILY_REWARD)

func set_coins(amount: int) -> void:
	top_appbar.set_coins(amount)

func set_eggs(amount: int) -> void:
	top_appbar.set_eggs(amount)

func set_evolution_progress(current: int, max: int, level: int) -> void:
	progress_value.text = "LVL " + str(level) + " · " + str(current) + "/" + str(max)
	var progress_percent = float(current) / float(max)
	bar_fill.custom_minimum_size.x = bar_fill.get_parent().size.x * progress_percent

func _on_tab_pressed(tab_name: String) -> void:
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

func set_active_tab(tab_name: String) -> void:
	bottom_nav.set_active(tab_name)

func _play_intro_animation() -> void:
	var creature_tween = create_tween()
	creature_tween.set_ease(Tween.EASE_IN_OUT)
	creature_tween.set_loops()
	creature_tween.tween_property(creature, "position:y", -143.0, 2.0)
	creature_tween.tween_property(creature, "position:y", -128.0, 2.0)
	
	var sparkle_tween = create_tween()
	sparkle_tween.set_ease(Tween.EASE_IN_OUT)
	sparkle_tween.set_loops()
	sparkle_tween.tween_property(sparkle, "modulate:a", 0.7, 1.0)
	sparkle_tween.tween_property(sparkle, "modulate:a", 1.0, 1.0)

func _on_play_pressed() -> void:
	GameState.go_to(GameState.Screen.MEMORY_SETUP)

func _on_merge_pressed() -> void:
	GameState.go_to(GameState.Screen.MERGE)

func _on_collection_pressed() -> void:
	GameState.go_to(GameState.Screen.COLLECTION)
