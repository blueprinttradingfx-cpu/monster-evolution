extends Node

var SCENE_MAP: Dictionary = {}
var _overlay_stack: Array = []

func _ready() -> void:
	SCENE_MAP = {
		GameState.Screen.BOOT: "res://scenes/boot/boot.tscn",
		GameState.Screen.SPLASH: "res://scenes/screens/splash/splash.tscn",
		GameState.Screen.TAP_TO_START: "res://scenes/screens/tap-to-start/tap-to-start.tscn",
		GameState.Screen.MENU: "res://scenes/screens/home/home.tscn",
		GameState.Screen.MEMORY_SETUP: "res://scenes/screens/memory-setup/memory-setup.tscn",
		GameState.Screen.MEMORY: "res://scenes/screens/memory/memory.tscn",
		GameState.Screen.RESULTS: "res://scenes/overlays/results_overlay.tscn",
		GameState.Screen.MERGE: "res://scenes/screens/merge/merge.tscn",
		GameState.Screen.COLLECTION: "res://scenes/screens/collection/collection.tscn",
		GameState.Screen.CREATURE_DETAIL: "res://scenes/screens/creature-detail/creature-detail.tscn",
		GameState.Screen.SHOP: "res://scenes/screens/shop/shop.tscn",
		GameState.Screen.SETTINGS: "res://scenes/screens/settings/settings.tscn"
	}
	GameState.screen_changed.connect(_on_screen_changed)

func _on_screen_changed(screen: GameState.Screen, extra: Dictionary) -> void:
	go_to(screen, extra)

func go_to(screen: GameState.Screen, extra: Dictionary = {}) -> void:
	if screen in [GameState.Screen.RESULTS]:
		var overlay_path: String = SCENE_MAP.get(screen, "")
		if overlay_path != "":
			push_overlay(load(overlay_path))
	else:
		var scene_path: String = SCENE_MAP.get(screen, "")
		if scene_path != "":
			_clear_overlays()
			get_tree().change_scene_to_file(scene_path)
			# For CREATURE_DETAIL, we'll need to set the creature after loading
			# (we'll use GameState.current_creature_id)

func push_overlay(overlay_scene: PackedScene) -> void:
	if _overlay_stack.size() > 0:
		pop_overlay()
	var overlay: Node = overlay_scene.instantiate()
	get_tree().root.add_child(overlay)
	_overlay_stack.append(overlay)

func pop_overlay() -> void:
	if _overlay_stack.size() > 0:
		var top_overlay: Node = _overlay_stack.pop_back()
		top_overlay.queue_free()

func get_current_screen() -> GameState.Screen:
	return GameState.current_screen

func _clear_overlays() -> void:
	for overlay in _overlay_stack:
		overlay.queue_free()
	_overlay_stack.clear()
