extends Node
## TutorialManager.gd
## Manages onboarding flow and UI locking.

signal step_changed(step_id: int)
signal tutorial_completed

var is_active := false
var is_enabled := false # KILLSWITCH: Set to true to enable tutorial system
var current_step := 0
var is_input_locked := false

var _registered_nodes := {} # name -> Node

var _overlay_scene = preload("res://scenes/overlays/tutorial/TutorialOverlay.tscn")
var _overlay_instance: CanvasLayer = null

func _ready() -> void:
	# Check if tutorial was already completed from SaveSystem
	var save_data = SaveSystem.get_data()
	var completed = save_data.get("progression", {}).get("tutorial_completed", false)

	if not completed:
		# We don't auto-start here, let GameState or Home screen decide
		pass

func start_tutorial() -> void:
	if not is_enabled:
		print("[Tutorial] System is disabled via killswitch.")
		return

	is_active = true
	current_step = 0
	is_input_locked = false

	if not _overlay_instance:
		_overlay_instance = _overlay_scene.instantiate()
		get_tree().root.add_child(_overlay_instance)

	_overlay_instance.show()
	_execute_step(current_step)

	step_changed.emit(current_step)
	print("[Tutorial] Started")

func next_step() -> void:
	current_step += 1
	_execute_step(current_step)
	step_changed.emit(current_step)
	print("[Tutorial] Advanced to step: ", current_step)

func refresh_step() -> void:
	if is_active:
		_execute_step(current_step)

func register_node(id: String, node: Node) -> void:
	_registered_nodes[id] = node
	if node is Node:
		if not node.is_connected("tree_exited", _on_node_freed):
			node.connect("tree_exited", _on_node_freed.bind(id))
	print("[Tutorial] Registered node: ", id)

func _on_node_freed(id: String) -> void:
	if _registered_nodes.get(id) != null:
		_registered_nodes.erase(id)
		print("[Tutorial] Unregistered freed node: ", id)

func get_registered_node(id: String) -> Node:
	var node = _registered_nodes.get(id, null)
	if node != null and is_instance_valid(node) and node.is_inside_tree():
		return node
	return null

func _execute_step(step_id: int) -> void:
	if not _overlay_instance: return

	match step_id:
		0: # Intro lock (Tap to Start or Home)
			var tap_btn = get_registered_node("tap_to_start_play_button")
			var home_btn = get_registered_node("home_start_button")

			if tap_btn:
				_overlay_instance.set_text("Welcome! Tap PLAY to start your journey.")
				highlight_node(tap_btn)
			elif home_btn:
				_overlay_instance.set_text("Tap START to begin your first challenge.")
				highlight_node(home_btn)
			else:
				_overlay_instance.set_text("Welcome! Tap PLAY to start your first challenge.")
		1: # First Memory tap
			_overlay_instance.hide_all() # Clear highlight and dimmer
			_overlay_instance.set_text("Find matching pairs to earn rewards.")
		2: # First match reveal
			_overlay_instance.set_text("Nice! You found a match!")
		3: # Board completion
			_overlay_instance.set_text("Great job! You cleared the board.")
		4: # Reward reveal
			_overlay_instance.set_text("You earned Eggs! These are used for evolution.")
		5: # First merge
			_overlay_instance.set_text("Go to the MERGE screen to evolve your monsters.")
		6: # First evolution unlock
			_overlay_instance.set_text("AMAZING! A new creature has been discovered.")
		7: # Return to home
			_overlay_instance.set_text("The loop is complete. Keep playing to find them all!")
			await get_tree().create_timer(3.0).timeout
			complete_tutorial()

func highlight_node(node: Control) -> void:
	if _overlay_instance:
		_overlay_instance.highlight_node(node)

func set_instruction(text: String) -> void:
	if _overlay_instance:
		_overlay_instance.set_text(text)

func complete_tutorial() -> void:
	is_active = false
	if _overlay_instance:
		_overlay_instance.hide_all()
	SaveSystem.set_progression_value("tutorial_completed", true)
	SaveSystem.save_game()
	tutorial_completed.emit()
	print("[Tutorial] Completed")
