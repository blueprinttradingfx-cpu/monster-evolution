extends Control

signal selected(creature_id: String)
signal dragging(position: Vector2)

var _creature_id: String = ""
var _count: int = 0
var _is_dragging: bool = false

func _ready() -> void:
	InputManager.tap.connect(_on_tap)
	InputManager.dragging.connect(_on_dragging)
	InputManager.drag_ended.connect(_on_drag_ended)

func _on_tap(tap_pos: Vector2) -> void:
	if get_global_rect().has_point(tap_pos):
		selected.emit(_creature_id)

func _on_dragging(drag_from: Vector2, drag_to: Vector2) -> void:
	if not get_global_rect().has_point(drag_from) and not _is_dragging:
		return

	if get_global_rect().has_point(drag_from):
		_is_dragging = true
	dragging.emit(drag_to)

func _on_drag_ended(drag_from: Vector2, drag_to: Vector2) -> void:
	_is_dragging = false

func setup(creature_id: String, count: int) -> void:
	_creature_id = creature_id
	_count = count
	var symbols: Array[String] = ["🦖", "🦕", "🐣", "🥚", "🦎", "🐊"]
	var creature_ids: Array[String] = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
	var idx: int = creature_ids.find(_creature_id)
	if idx == -1:
		idx = _creature_id.hash() % symbols.size()
	$Icon.text = symbols[idx]
	$CountLabel.text = str(count)

func reset() -> void:
	_creature_id = ""
	_count = 0
	_is_dragging = false
	$Icon.text = ""
	$CountLabel.text = ""
