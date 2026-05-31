extends Control

@onready var coins_label: Label = $SafeArea/VBoxContainer/TopBar/CoinsLabel
@onready var back_button: Button = $SafeArea/VBoxContainer/TopBar/BackButton
@onready var inventory_grid: GridContainer = $SafeArea/VBoxContainer/InventoryGrid
@onready var slot_a: Panel = $SafeArea/VBoxContainer/MergeArea/SlotA
@onready var slot_b: Panel = $SafeArea/VBoxContainer/MergeArea/SlotB
@onready var merge_button: Button = $SafeArea/VBoxContainer/MergeArea/MergeButton
@onready var preview_label: Label = $SafeArea/VBoxContainer/PreviewLabel

var _selected_creature: String = ""
var _slot_a_creature: String = ""
var _slot_b_creature: String = ""

func _ready() -> void:
	_refresh_ui()
	MergeSystem.inventory_updated.connect(_refresh_ui)
	MergeSystem.merge_succeeded.connect(_on_merge_succeeded)
	MergeSystem.merge_failed.connect(_on_merge_failed)
	back_button.pressed.connect(_on_back_pressed)
	merge_button.pressed.connect(_on_merge_pressed)

func _refresh_ui() -> void:
	var data: Dictionary = SaveSystem.get_data()
	coins_label.text = "Coins: %d" % data["economy"]["coins"]
	_populate_inventory(SaveSystem.get_inventory())

func _populate_inventory(inventory: Dictionary) -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	
	var creature_item_scene: PackedScene = load("res://ui_components/creature_item.tscn")
	
	for creature_id in inventory:
		var count: int = inventory[creature_id]
		var creature_item: Control = creature_item_scene.instantiate()
		creature_item.setup(creature_id, count)
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

func _set_slot(slot: Panel, creature_id: String) -> void:
	for child in slot.get_children():
		if child is Label:
			child.text = MergeSystem.get_creature_name(creature_id)
			break

func _check_merge_possible() -> void:
	if MergeSystem.can_merge(_slot_a_creature, _slot_b_creature):
		var next_id: String = MergeSystem.get_next_evolution(_slot_a_creature)
		preview_label.text = "Result: %s" % MergeSystem.get_creature_name(next_id)
		merge_button.disabled = false
	else:
		preview_label.text = "Can't merge these!"
		merge_button.disabled = true

func _on_merge_pressed() -> void:
	MergeSystem.merge(_slot_a_creature, _slot_b_creature)

func _on_merge_succeeded(result_id: String, level: int) -> void:
	_slot_a_creature = ""
	_slot_b_creature = ""
	_set_slot(slot_a, "")
	_set_slot(slot_b, "")
	for child in slot_a.get_children():
		if child is Label:
			child.text = "Slot A"
	for child in slot_b.get_children():
		if child is Label:
			child.text = "Slot B"
	preview_label.text = ""
	merge_button.disabled = true
	_refresh_ui()

func _on_merge_failed(reason: String) -> void:
	preview_label.text = reason

func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)
