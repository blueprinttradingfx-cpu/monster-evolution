extends PanelContainer

@onready var tag_panel: PanelContainer = $VBox/TagRow/TagPanel
@onready var tag_label: Label = $VBox/TagRow/TagPanel/TagLabel
@onready var card_num_label: Label = $VBox/TagRow/CardNum
@onready var img_bg: PanelContainer = $VBox/ImgBg
@onready var img_label: Label = $VBox/ImgBg/ImgLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var stars_label: Label = $VBox/StarsLabel

var _is_unlocked: bool = false
var _creature_id: String = ""

@export var style_discovered: StyleBoxFlat
@export var style_locked: StyleBoxFlat
@export var style_img_bg: StyleBoxFlat
@export var style_img_locked_bg: StyleBoxFlat

func setup(creature_id: String, is_unlocked: bool, index: int, symbol: String, name_text: String) -> void:
	_creature_id = creature_id
	_is_unlocked = is_unlocked

	card_num_label.text = "#%03d" % index

	if is_unlocked:
		name_label.text = name_text.to_upper()
		img_label.text = symbol
		modulate = Color(1, 1, 1, 1)
		if style_discovered:
			add_theme_stylebox_override("panel", style_discovered)
		if style_img_bg:
			img_bg.add_theme_stylebox_override("panel", style_img_bg)

		# Flavor tags - could be data driven later
		tag_label.text = "MONSTER"
		stars_label.text = "★★★☆☆"
		stars_label.modulate = Color(1, 1, 1, 1)
	else:
		name_label.text = "LOCKED"
		img_label.text = "❓"
		modulate = Color(1, 1, 1, 0.8)
		if style_locked:
			add_theme_stylebox_override("panel", style_locked)
		if style_img_locked_bg:
			img_bg.add_theme_stylebox_override("panel", style_img_locked_bg)

		tag_label.text = "???"
		stars_label.text = "☆☆☆☆☆"
		stars_label.modulate = Color(1, 1, 1, 0.5)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_card()
			else:
				_release_card()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_card()
		else:
			_release_card()

func _press_card() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", 4.0, 0.06).as_relative()

func _release_card() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", -4.0, 0.08).as_relative()
