extends Control

@onready var top_appbar: TopAppBar = $TopAppBar
@onready var inventory_grid: GridContainer = $ScrollContainer/ContentVBox/InventorySection/InventoryGrid
@onready var slot_a: PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot1
@onready var slot_b: PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot2
@onready var merge_button: Button = $ScrollContainer/ContentVBox/MergeButton
@onready var preview_label: Label = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/PreviewBox/PreviewVBox/PreviewLabel
@onready var bottom_nav: BottomNav = $BottomNav

var _selected_creature: String = ""
var _slot_a_creature: String = ""
var _slot_b_creature: String = ""

func _ready() -> void:
	_refresh_ui()
	MergeSystem.inventory_updated.connect(_refresh_ui)
	MergeSystem.merge_succeeded.connect(_on_merge_succeeded)
	MergeSystem.merge_failed.connect(_on_merge_failed)
	merge_button.pressed.connect(_on_merge_pressed)
	
	# Connect BottomNav
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.set_active("merge")
	
	# Hide StartButton in BottomNav for this screen
	bottom_nav.start_button.visible = false

func _refresh_ui() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)
	_populate_inventory(SaveSystem.get_inventory())

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

func _on_creature_selected(creature_id: String) -> void:
	if _slot_a_creature == "":
		_slot_a_creature = creature_id
		_set_slot(slot_a, creature_id)
	elif _slot_b_creature == "":
		_slot_b_creature = creature_id
		_set_slot(slot_b, creature_id)
		_check_merge_possible()

func _set_slot(slot: PanelContainer, creature_id: String) -> void:
	for child in slot.get_children():
		if child is Label:
			if creature_id == "":
				child.text = "🧩"
			else:
				# For now just use emoji, but can use MergeSystem later
				child.text = "🟢"
			break

func _check_merge_possible() -> void:
	if _slot_a_creature and _slot_b_creature:
		preview_label.text = "Result: Sparkle Blob"
		merge_button.disabled = false
	else:
		preview_label.text = "Next: Sparkle Blob"
		merge_button.disabled = true

func _on_merge_pressed() -> void:
	# Call MergeSystem if it exists, otherwise just reset
	if is_instance_valid(MergeSystem):
		MergeSystem.merge(_slot_a_creature, _slot_b_creature)
	else:
		_on_merge_succeeded("sparkle_blob", 1)

func _on_merge_succeeded(result_id: String, level: int) -> void:
	_slot_a_creature = ""
	_slot_b_creature = ""
	_set_slot(slot_a, "")
	_set_slot(slot_b, "")
	preview_label.text = "Next: Sparkle Blob"
	merge_button.disabled = true
	_refresh_ui()

func _on_merge_failed(reason: String) -> void:
	preview_label.text = reason

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
