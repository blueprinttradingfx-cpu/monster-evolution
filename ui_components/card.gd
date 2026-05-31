extends Control

signal card_pressed(grid_pos: Vector2i)

var _card_data: Object
var _grid_pos: Vector2i = Vector2i(0, 0)
var _is_flipped: bool = false
var _is_matched: bool = false
var _is_animating: bool = false

func _ready() -> void:
	InputManager.tap.connect(_on_tap)

func _on_tap(tap_pos: Vector2) -> void:
	if _is_animating:
		return
	if MemorySystem.input_locked:
		return
	if _is_flipped:
		return
	if _is_matched:
		return

	var is_tapped: bool = get_global_rect().has_point(tap_pos)
	if is_tapped:
		flip_to_front()
		MemorySystem.flip_card(_grid_pos)
		card_pressed.emit(_grid_pos)

func setup(card_data: Object, grid_pos: Vector2i) -> void:
	_card_data = card_data
	_grid_pos = grid_pos
	_is_flipped = false
	_is_matched = false
	_is_animating = false
	$BackFace.visible = true
	$FrontFace.visible = false
	self.modulate = Color.WHITE
	self.scale = Vector2(1,1)

func flip_to_front() -> void:
	_is_animating = true
	_is_flipped = true

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 0.01, 0.15)
	await tween.finished

	var symbols: Array[String] = ["🦖", "🦕", "🐣", "🥚", "🦎", "🐊"]
	var creature_ids: Array[String] = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
	var idx: int = creature_ids.find(_card_data.id)
	if idx == -1:
		idx = _card_data.id.hash() % symbols.size()
	$FrontFace.text = symbols[idx]
	$FrontFace.visible = true
	$BackFace.visible = false

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	await tween.finished
	_is_animating = false

func flip_to_back() -> void:
	_is_animating = true
	_is_flipped = false

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 0.01, 0.15)
	await tween.finished

	$FrontFace.visible = false
	$BackFace.visible = true

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	await tween.finished
	_is_animating = false

func set_matched() -> void:
	_is_matched = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.2)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.2)
	lock()

func lock() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	_is_flipped = false
	_is_matched = false
	_is_animating = false
	$FrontFace.visible = false
	$BackFace.visible = true
	self.scale = Vector2(1, 1)
	self.modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_STOP
