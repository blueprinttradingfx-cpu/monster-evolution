extends Control

@onready var resume_button: Button = $CanvasLayer/Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CanvasLayer/Panel/VBoxContainer/RestartButton
@onready var exit_button: Button = $CanvasLayer/Panel/VBoxContainer/ExitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_resume_pressed() -> void:
	NavigationManager.pop_overlay()
	get_tree().paused = false

func _on_restart_pressed() -> void:
	NavigationManager.pop_overlay()
	MemorySystem.generate_board(MemorySystem.grid_size, "dino")
	get_tree().paused = false

func _on_exit_pressed() -> void:
	NavigationManager.pop_overlay()
	GameState.go_to(GameState.Screen.MENU)
	get_tree().paused = false
