extends Control

@onready var theme_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/ThemeRow/ThemeInfo/ThemeValue
@onready var grid_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/GridSizeCard/GridSizeVBox/GridSizeValue
@onready var diff_dot: ColorRect = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffDot
@onready var diff_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffValue
@onready var bottom_nav: BottomNav = $BottomNav
@onready var start_button: Button = $StartButton

func _ready() -> void:
	_populate_level_info()
	start_button.pressed.connect(_on_start_pressed)
	_play_hero_fade_in()
	
	# Connect bottom nav buttons
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.set_active("play")
	
	# Set all label font sizes to 24px
	theme_value.add_theme_font_size_override("font_size", 24)
	grid_value.add_theme_font_size_override("font_size", 24)
	diff_value.add_theme_font_size_override("font_size", 24)

func _populate_level_info() -> void:
	var level_idx: int = SaveSystem.get_data().get("progression", {}).get("boards_cleared", 0)
	var grid_size: Vector2i = MemorySystem.get_current_difficulty()
	grid_value.text = "%dx%d" % [grid_size.x, grid_size.y]
	
	# Difficulty based on grid size
	var total_cells: int = grid_size.x * grid_size.y
	var difficulty_name: String
	var difficulty_color: Color
	
	match total_cells:
		0-6:
			difficulty_name = "Easy"
			difficulty_color = Color(0.204, 0.831, 0.600, 1.0)
		7-12:
			difficulty_name = "Medium"
			difficulty_color = Color(0.992, 0.878, 0.278, 1.0)
		_:
			difficulty_name = "Hard"
			difficulty_color = Color(0.925, 0.286, 0.600, 1.0)
	
	diff_value.text = difficulty_name
	diff_dot.color = difficulty_color
	
	# Theme
	theme_value.text = "Dinosaurs"  # Can be expanded later to use different themes

func _play_hero_fade_in() -> void:
	var hero = $ScrollContainer/ContentVBox/HeroSection
	hero.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(hero, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	GameState.go_to(GameState.Screen.MEMORY)

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
