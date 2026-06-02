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

	if has_node("/root/TutorialSystem"):
		var tutorial = get_node("/root/TutorialSystem")
		tutorial.register_node("home_start_button", play_button)
		if not SaveSystem.get_data().get("progression", {}).get("tutorial_completed", false):
			if not tutorial.is_active:
				tutorial.start_tutorial()
			else:
				tutorial.refresh_step()

	merge_button.pressed.connect(_on_merge_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.set_active("play")
	_update_evolution_progress()
	
	if SaveSystem.check_daily_reward():
		GameState.go_to(GameState.Screen.DAILY_REWARD)
	
	# Set all label font sizes to 24px
	progress_title.add_theme_font_size_override("font_size", 24)
	progress_value.add_theme_font_size_override("font_size", 24)
	
	# Set all button font sizes to 24px
	play_button.add_theme_font_size_override("font_size", 24)
	merge_button.add_theme_font_size_override("font_size", 24)
	collection_button.add_theme_font_size_override("font_size", 24)

func _update_evolution_progress() -> void:
	var unlocked_creatures: Array[String] = MergeSystem.get_unlocked_creatures()
	if unlocked_creatures.is_empty():
		return
	
	var highest_evo: int = 0
	var highest_creature: String = ""
	for creature_id in unlocked_creatures:
		var evo_level: int = MergeSystem.get_evolution_level(creature_id)
		if evo_level > highest_evo:
			highest_evo = evo_level
			highest_creature = creature_id
	
	if highest_creature == "":
		return
	
	var next_evo: String = MergeSystem.get_next_evolution(highest_creature)
	if next_evo == "":
		# Max level
		set_evolution_progress(1, 1, highest_evo)
		return
	
	var current_count: int = SaveSystem.get_inventory_count(highest_creature)
	var required_count: int = MergeSystem.get_merge_required(highest_creature)
	
	set_evolution_progress(current_count, required_count, highest_evo)

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
	_emit_juice("button_press", {"node": play_button})
	if has_node("/root/TutorialSystem") and get_node("/root/TutorialSystem").is_active:
		if get_node("/root/TutorialSystem").current_step == 0:
			get_node("/root/TutorialSystem").next_step()

	GameState.go_to(GameState.Screen.MEMORY_SETUP)

func _on_merge_pressed() -> void:
	_emit_juice("button_press", {"node": merge_button})
	GameState.go_to(GameState.Screen.MERGE)

func _on_collection_pressed() -> void:
	_emit_juice("button_press", {"node": collection_button})
	GameState.go_to(GameState.Screen.COLLECTION)

func _emit_juice(type: String, payload: Dictionary) -> void:
	var juice = get_node_or_null("/root/UIJuiceLayer")
	if juice: juice.on_event(type, payload)
