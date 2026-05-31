extends Control

@onready var theme_label: Label = $SafeArea/VBoxContainer/ThemeLabel
@onready var difficulty_label: Label = $SafeArea/VBoxContainer/DifficultyLabel
@onready var grid_label: Label = $SafeArea/VBoxContainer/GridLabel
@onready var start_button: Button = $SafeArea/VBoxContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	var save_data: Dictionary = SaveSystem.get_data()
	var difficulty: int = save_data["progression"]["boards_cleared"]
	var grid_size: Vector2i = MemorySystem.get_next_difficulty(difficulty)
	
	# Update UI
	if difficulty < 5:
		difficulty_label.text = "Difficulty: Easy"
	elif difficulty < 10:
		difficulty_label.text = "Difficulty: Medium"
	else:
		difficulty_label.text = "Difficulty: Hard"
	grid_label.text = "Grid: %dx%d" % [grid_size.x, grid_size.y]

func _on_start_pressed() -> void:
	GameState.go_to(GameState.Screen.MEMORY)
