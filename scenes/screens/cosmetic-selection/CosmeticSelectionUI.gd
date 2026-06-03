extends Control

# Cosmetic Selection UI - Overlay for selecting/equipping cosmetics on monsters
# Per TICKET-26

# --- SIGNALS ---
signal cosmetic_selected(slot: String, cosmetic_id: String)
signal selection_cancelled()

# --- NODES ---
@onready var slot_buttons_container: HBoxContainer = $MainContent/SlotButtons
@onready var cosmetic_options_container: HBoxContainer = $MainContent/CosmeticOptions
@onready var cancel_button: Button = $MainContent/CancelButton
@onready var unequip_button: Button = $MainContent/UnequipButton

# --- VARIABLES ---
var _monster_id: String = ""
var _selected_slot: String = "head"
var _selected_cosmetic_id: String = ""
var _slots: Array = ["head", "face", "body", "back"]

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)

func open(monster_id: String) -> void:
	_monster_id = monster_id
	_selected_slot = "head"
	_selected_cosmetic_id = ""
	_clear_slot_buttons()
	_clear_cosmetic_options()
	_populate_slot_buttons()
	_populate_cosmetic_options()
	visible = true

func _clear_slot_buttons() -> void:
	for child in slot_buttons_container.get_children():
		child.queue_free()

func _clear_cosmetic_options() -> void:
	for child in cosmetic_options_container.get_children():
		child.queue_free()

func _populate_slot_buttons() -> void:
	for slot in _slots:
		var button: Button = Button.new()
		button.text = slot.capitalize()
		button.custom_minimum_size = Vector2(100, 60)
		button.pressed.connect(func(): _on_slot_selected(slot))
		if slot == _selected_slot:
			button.disabled = true
		slot_buttons_container.add_child(button)

func _populate_cosmetic_options() -> void:
	if not MonsterManager or _monster_id.is_empty():
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var species_id: String = monster_data.get("speciesId", "")
	var available_cosmetics: Array = MonsterManager.get_owned_cosmetics_for_slot(species_id, _selected_slot)
	var equipped_cosmetic_id: String = MonsterManager.get_equipped_cosmetic(_monster_id, _selected_slot)
	
	for cosmetic_id in available_cosmetics:
		_add_cosmetic_option(cosmetic_id, (cosmetic_id == equipped_cosmetic_id))

func _add_cosmetic_option(cosmetic_id: String, is_equipped: bool) -> void:
	var button: Button = Button.new()
	var path := "res://data/cosmetics/%s.tres" % cosmetic_id
	var res: Resource = load(path)
	var display_name: String = cosmetic_id
	if res and res is Cosmetic:
		display_name = res.name
	
	button.text = display_name + (" (Equipped)" if is_equipped else "")
	button.custom_minimum_size = Vector2(200, 100)
	button.pressed.connect(func(): _on_cosmetic_selected(cosmetic_id))
	cosmetic_options_container.add_child(button)

func _on_slot_selected(slot: String) -> void:
	_selected_slot = slot
	_clear_slot_buttons()
	_clear_cosmetic_options()
	_populate_slot_buttons()
	_populate_cosmetic_options()

func _on_cosmetic_selected(cosmetic_id: String) -> void:
	_selected_cosmetic_id = cosmetic_id
	if MonsterManager and _monster_id:
		MonsterManager.equip_cosmetic(_monster_id, _selected_slot, cosmetic_id)
	cosmetic_selected.emit(_selected_slot, cosmetic_id)
	visible = false

func _on_unequip_pressed() -> void:
	if MonsterManager and _monster_id:
		MonsterManager.unequip_cosmetic(_monster_id, _selected_slot)
	cosmetic_selected.emit(_selected_slot, "")
	visible = false

func _on_cancel_pressed() -> void:
	selection_cancelled.emit()
	visible = false

