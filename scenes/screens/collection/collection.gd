extends Control

@onready var collection_grid: GridContainer = $SafeArea/VBoxContainer/CollectionGrid
@onready var progress_label: Label = $SafeArea/VBoxContainer/Header/ProgressLabel
@onready var back_button: Button = $SafeArea/VBoxContainer/Header/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	MergeSystem.creature_unlocked.connect(_populate_collection)
	MergeSystem.inventory_updated.connect(_populate_collection)
	_populate_collection()

func _populate_collection() -> void:
	var all_creature_ids: Array = MergeSystem.get_all_creature_ids()
	var unlocked_count: int = 0
	
	for child in collection_grid.get_children():
		child.queue_free()
	
	for creature_id in all_creature_ids:
		var is_unlocked: bool = MergeSystem.is_unlocked(creature_id)
		if is_unlocked:
			unlocked_count += 1
		var creature_card: Control = _create_creature_card(creature_id, is_unlocked)
		collection_grid.add_child(creature_card)
	
	progress_label.text = "%s/%s" % [unlocked_count, all_creature_ids.size()]

func _create_creature_card(creature_id: String, is_unlocked: bool) -> Control:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(80, 80)
	card.layout_mode = 2
	
	var symbols: Array[String] = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
	var creature_ids: Array[String] = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
	var idx: int = creature_ids.find(creature_id)
	if idx == -1:
		idx = creature_id.hash() % symbols.size()
	
	var icon: Label = Label.new()
	icon.layout_mode = 1
	icon.anchors_preset = 15
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.grow_horizontal = 2
	icon.grow_vertical = 2
	if is_unlocked:
		icon.text = symbols[idx]
	else:
		icon.text = "?"
	icon.horizontal_alignment = 1
	icon.vertical_alignment = 1
	card.add_child(icon)
	
	if not is_unlocked:
		var lock_overlay: ColorRect = ColorRect.new()
		lock_overlay.layout_mode = 1
		lock_overlay.anchors_preset = 15
		lock_overlay.anchor_right = 1.0
		lock_overlay.anchor_bottom = 1.0
		lock_overlay.grow_horizontal = 2
		lock_overlay.grow_vertical = 2
		lock_overlay.color = Color(0, 0, 0, 0.5)
		card.add_child(lock_overlay)
	
	var name_label: Label = Label.new()
	name_label.layout_mode = 2
	if is_unlocked:
		name_label.text = MergeSystem.get_creature_name(creature_id)
	else:
		name_label.text = "???"
	name_label.horizontal_alignment = 1
	card.add_child(name_label)
	
	# Connect button click
	card.pressed.connect(func(): _on_creature_clicked(creature_id))
	
	return card

func _on_creature_clicked(creature_id: String) -> void:
	GameState.go_to(GameState.Screen.CREATURE_DETAIL, {"creature_id": creature_id})

func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)
