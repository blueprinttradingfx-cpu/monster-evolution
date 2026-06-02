extends Control

@onready var top_appbar: TopAppBar = $TopAppBar
@onready var inventory_grid: GridContainer = $ScrollContainer/ContentVBox/InventorySection/InventoryGrid
@onready var slot_a: PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot1
@onready var slot_b: PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot2
@onready var merge_button: Button = $ScrollContainer/ContentVBox/MergeButton
@onready var preview_label: Label = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/PreviewBox/PreviewVBox/PreviewLabel
@onready var bottom_nav: BottomNav = $BottomNav

var _selected_creature: String = ""

func _ready() -> void:
	# Clear old session rewards
	GameState.session_rewards = {}
	_refresh_ui()
	MergeSystem.inventory_updated.connect(_refresh_ui)
	MergeSystem.merge_success.connect(_on_merge_success)
	MergeSystem.merge_failed.connect(_on_merge_failed)
	merge_button.pressed.connect(_on_merge_pressed)

	# Connect BottomNav
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.set_active("merge")


	# Check if a creature was pre-selected (coming from collection)
	var pre_selected: String = GameState.merge_selected_creature_id
	if pre_selected != "":
		_selected_creature = pre_selected
		GameState.merge_selected_creature_id = ""  # Clear after use
		_update_merge_ui()

	# Make slots clickable for manual selection
	_setup_slot_clickable(slot_a)
	_setup_slot_clickable(slot_b)

func _refresh_ui(inventory: Dictionary = {}) -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)
	_populate_inventory(SaveSystem.get_inventory())
	_update_merge_ui()

func _populate_inventory(inventory: Dictionary) -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	# Check if creature_item.tscn exists first
	var creature_item_scene_path = "res://ui_components/creature_item.tscn"
	if ResourceLoader.exists(creature_item_scene_path):
		var creature_item_scene: PackedScene = load(creature_item_scene_path)
		for creature_id in inventory:
			var count: int = inventory[creature_id]
			var creature_item: Control = creature_item_scene.instantiate()
			if creature_item.has_method("setup"):
				creature_item.setup(creature_id, count)
			if creature_item.has_signal("selected"):
				creature_item.selected.connect(_on_creature_selected)
			inventory_grid.add_child(creature_item)
	else:
		# Fallback: create simple buttons
		for creature_id in inventory:
			var count: int = inventory[creature_id]
			var btn := Button.new()
			btn.text = "%s x%d" % [creature_id, count]
			btn.pressed.connect(_on_creature_selected.bind(creature_id))
			inventory_grid.add_child(btn)

func _on_creature_selected(creature_id: String) -> void:
	_selected_creature = creature_id
	_update_merge_ui()

func _update_merge_ui() -> void:
	if _selected_creature == "":
		_set_slot(slot_a, "")
		_set_slot(slot_b, "")
		preview_label.text = "Select a creature to merge"
		merge_button.disabled = true
		return

	# Show selected creature in slot A
	_set_slot(slot_a, _selected_creature)

	# Check if merge is possible
	var can_merge := MergeSystem.can_merge(_selected_creature)
	var next_evolution := MergeSystem.get_next_evolution(_selected_creature)

	if can_merge and next_evolution != "":
		_set_slot(slot_b, next_evolution)
		preview_label.text = "Result: " + next_evolution.capitalize()
		merge_button.disabled = false
	else:
		_set_slot(slot_b, "")
		if next_evolution == "":
			preview_label.text = "Max evolution reached"
		else:
			preview_label.text = "Need more creatures"
		merge_button.disabled = true

func _set_slot(slot: PanelContainer, creature_id: String) -> void:
	for child in slot.get_children():
		if child is Label:
			if creature_id == "":
				child.text = "🧩"
			else:
				# Use actual creature symbol
				if has_node("/root/CreatureRegistry"):
					var data = get_node("/root/CreatureRegistry").get_creature(creature_id)
					if data:
						child.text = data.symbol
					else:
						child.text = "🟢"  # Fallback
				else:
					child.text = "🟢"  # Fallback
			break

func _on_merge_pressed() -> void:
	if _selected_creature != "":
		MergeSystem.merge(_selected_creature)

func _on_merge_success(result_id: String, level: int) -> void:
	_selected_creature = ""
	_update_merge_ui()
	_refresh_ui()

func _on_merge_failed(reason: String) -> void:
	preview_label.text = reason

func _setup_slot_clickable(slot: PanelContainer) -> void:
	slot.gui_input.connect(_on_slot_gui_input.bind(slot))

func _on_slot_gui_input(event: InputEvent, slot: PanelContainer) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Clicking a slot clears selection and lets user choose from inventory
			_selected_creature = ""
			_update_merge_ui()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Clicking a slot clears selection and lets user choose from inventory
			_selected_creature = ""
			_update_merge_ui()

func _on_tab_pressed(tab_name: String) -> void:
	bottom_nav.set_active(tab_name)
	match tab_name:
		"play":
			GameState.go_to(GameState.Screen.MENU)
		"collection":
			GameState.go_to(GameState.Screen.COLLECTION)
		"shop":
			GameState.go_to(GameState.Screen.SHOP)
		"settings":
			GameState.go_to(GameState.Screen.SETTINGS)
