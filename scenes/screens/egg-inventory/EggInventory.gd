extends Control

# Egg Inventory UI - Display owned eggs and allow hatching

signal hatch_egg_requested(owned_egg_id: String)

@onready var _egg_list: VBoxContainer = $EggList
@onready var _no_eggs_label: Label = $NoEggsLabel

func _ready() -> void:
	_refresh_egg_list()

func _refresh_egg_list() -> void:
	# Clear existing items
	for child in _egg_list.get_children():
		child.queue_free()
	
	# Get owned eggs
	var eggs: Array = []
	if MonsterManager:
		eggs = MonsterManager.get_owned_eggs()
	
	# Show no eggs label if no eggs
	if eggs.is_empty():
		_no_eggs_label.visible = true
		return
	
	_no_eggs_label.visible = false
	
	# Create egg items
	for egg_data in eggs:
		var egg_item: Button = Button.new()
		egg_item.text = "%s (Tap to Hatch)" % _get_egg_name(egg_data.eggTypeId)
		egg_item.custom_minimum_size = Vector2(200, 60)
		egg_item.pressed.connect(func(): _on_egg_pressed(egg_data.id))
		_egg_list.add_child(egg_item)

func _get_egg_name(egg_type_id: String) -> String:
	match egg_type_id:
		"dino_egg":
			return "Dino Egg"
		"slime_egg":
			return "Slime Egg"
		_:
			return egg_type_id.capitalize()

func _on_egg_pressed(owned_egg_id: String) -> void:
	hatch_egg_requested.emit(owned_egg_id)
