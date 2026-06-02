extends Button

signal card_pressed(grid_pos: Vector2i)

var _card_data
var _grid_pos: Vector2i = Vector2i(0, 0)
var _is_flipped: bool = false
var _is_matched: bool = false
var _is_animating: bool = false

func _ready() -> void:
	pressed.connect(_on_self_pressed)

func is_flipped() -> bool:
	return _is_flipped

func _on_self_pressed() -> void:
	print("Card (name: %s) pressed!" % self.name)
	print("  _is_animating: %s, _is_flipped: %s, _is_matched: %s" % [str(_is_animating), str(_is_flipped), str(_is_matched)])
	if _is_animating:
		print("  → Skipping - animating")
		return
	if _is_flipped:
		print("  → Skipping - already flipped")
		return
	if _is_matched:
		print("  → Skipping - matched")
		return

	card_pressed.emit(_grid_pos)

func setup(card_data, grid_pos: Vector2i) -> void:
	_card_data = card_data
	_grid_pos = grid_pos
	_is_flipped = false
	_is_matched = false
	_is_animating = false
	$BackFace.visible = true
	$BackFace.text = "?"
	$BackFace.theme_type_variation = ""
	$BackFace.add_theme_color_override("font_color", Color.BLACK)
	$BackFace.add_theme_font_size_override("font_size", 24)
	$FrontFace.visible = false
	var monster_label = $FrontFace.get_node_or_null("MonsterLabel")
	if monster_label:
		monster_label.text = ""
	$Bg.visible = true
	$FlippedBg.visible = false
	self.modulate = Color.WHITE
	self.scale = Vector2(1,1)

func flip_to_front() -> void:
	_is_animating = true
	_is_flipped = true

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 0.01, 0.15)
	await tween.finished

	$FrontFace.visible = true
	$BackFace.visible = false
	$Bg.visible = false
	$FlippedBg.visible = true

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	await tween.finished
	_is_animating = false

func flip_to_back() -> void:
	print("Card (name: %s) flipping back" % self.name)
	_is_animating = true
	_is_flipped = false

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 0.01, 0.15)
	await tween.finished
	print("  Finished first tween 1")

	$FrontFace.visible = false
	$BackFace.visible = true
	$Bg.visible = true
	$FlippedBg.visible = false
	print("  Updated node visibilities")

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	await tween.finished
	print("  Finished second tween")
	_is_animating = false

func set_matched() -> void:
	_is_matched = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.2)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.2)
	lock()

func lock() -> void:
	disabled = true

func play_match_fx() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func play_mismatch_fx() -> void:
	var original_pos = position
	var tween = create_tween()
	for i in range(4):
		var offset = Vector2(5,0) if i % 2 == 0 else Vector2(-5,0)
		tween.tween_property(self, "position", original_pos + offset, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func reset() -> void:
	set_process(false)
	_card_data = null
	_grid_pos = Vector2i(0, 0)
	_is_flipped = false
	_is_matched = false
	_is_animating = false
	$FrontFace.visible = false
	$BackFace.visible = true
	$Bg.visible = true
	$FlippedBg.visible = false
	self.scale = Vector2(1, 1)
	self.modulate = Color.WHITE
	disabled = false  # Ensure card is clickable again
