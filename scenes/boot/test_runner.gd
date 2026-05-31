extends Node

func _ready():
	await get_tree().process_frame
	GameState.go_to(GameState.Screen.SPLASH)
