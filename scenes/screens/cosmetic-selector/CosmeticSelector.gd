extends Control

# Cosmetic Selector - Popup for selecting cosmetics to equip
# Per TICKET-26

signal cosmetic_selected(cosmetic_id: String)
signal unequip_requested()

var _monster_id: String = ""
var _current_slot: String = "head"

@onready var _background: ColorRect = $Background
@onready var _panel: PanelContainer = $Panel
@onready var _head_button: Button = $Panel/VBox/SlotFilter/HeadButton
@onready var _face_button: Button = $Panel/VBox/SlotFilter/FaceButton
@onready var _body_button: Button = $Panel/VBox/SlotFilter/BodyButton
@onready var _list_content: VBoxContainer = $Panel/VBox/CosmeticList/ListContent
@onready var _unequip_button: Button = $Panel/VBox/UnequipButton
@onready var _close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	_background.gui_input.connect(_on_background_input)
	_head_button.pressed.connect(func(): _set_slot("head"))
	_face_button.pressed.connect(func(): _set_slot("face"))
	_body_button.pressed.connect(func(): _set_slot("body"))
	_unequip_button.pressed.connect(_on_unequip_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	
	# Connect button press animations
	_head_button.pressed.connect(func(): _play_button_press_animation(_head_button))
	_face_button.pressed.connect(func(): _play_button_press_animation(_face_button))
	_body_button.pressed.connect(func(): _play_button_press_animation(_body_button))
	_unequip_button.pressed.connect(func(): _play_button_press_animation(_unequip_button))
	_close_button.pressed.connect(func(): _play_button_press_animation(_close_button))
	
	_set_slot("head")
	_play_popup_animation()

func setup(monster_id: String) -> void:
	_monster_id = monster_id
	_refresh_list()

func _set_slot(slot: String) -> void:
	_current_slot = slot
	_refresh_list()

func _refresh_list() -> void:
	# Clear existing items
	for child in _list_content.get_children():
		child.queue_free()
	
	if not MonsterManager:
		return
	
	# Get owned cosmetics for current slot and monster species
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	var species_id: String = monster_data.get("speciesId", "")
	
	var owned_cosmetics: Array = []
	for cosmetic_id in MonsterManager.owned_cosmetic_ids:
		var cosmetic_path := "res://data/cosmetics/%s.tres" % cosmetic_id
		var cosmetic: Resource = load(cosmetic_path)
		if cosmetic and cosmetic is Cosmetic:
			if cosmetic.slot == _current_slot and cosmetic.speciesId == species_id:
				owned_cosmetics.append(cosmetic)
	
	# Add cosmetic items to list
	for cosmetic in owned_cosmetics:
		var item_button: Button = Button.new()
		item_button.text = cosmetic.name
		item_button.custom_minimum_size = Vector2(0, 48)
		item_button.pressed.connect(func(): _on_cosmetic_selected(cosmetic.id))
		item_button.pressed.connect(func(): _play_button_press_animation(item_button))
		_list_content.add_child(item_button)
	
	if owned_cosmetics.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No cosmetics for this slot"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list_content.add_child(empty_label)

func _on_cosmetic_selected(cosmetic_id: String) -> void:
	cosmetic_selected.emit(cosmetic_id)
	queue_free()

func _on_unequip_pressed() -> void:
	unequip_requested.emit()
	queue_free()

func _on_close_pressed() -> void:
	queue_free()

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		queue_free()

func _play_button_press_animation(button: Button) -> void:
	if not button:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _play_popup_animation() -> void:
	# Scale up from center
	_panel.scale = Vector2(0.5, 0.5)
	_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
