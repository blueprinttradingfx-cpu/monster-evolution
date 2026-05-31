extends Node

signal tap(position: Vector2)
signal drag_started(position: Vector2)
signal dragging(from: Vector2, to: Vector2)
signal drag_ended(from: Vector2, to: Vector2)
signal long_press(position: Vector2)

var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _touch_start_time: float = 0.0

const LONG_PRESS_TIME: float = 0.5
const DRAG_THRESHOLD: float = 20.0

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _on_touch_down(event.position)
        else:
            _on_touch_up(event.position)

    elif event is InputEventScreenDrag:
        _on_drag(event.position)

func _on_touch_down(pos: Vector2) -> void:
    _touch_start_pos = pos
    _touch_start_time = Time.get_ticks_msec() / 1000.0
    _is_dragging = false

func _on_touch_up(pos: Vector2) -> void:
    var duration: float = (Time.get_ticks_msec() / 1000.0) - _touch_start_time
    var distance: float = pos.distance_to(_touch_start_pos)

    if _is_dragging:
        emit_signal("drag_ended", _touch_start_pos, pos)
        _is_dragging = false
        return

    if duration >= LONG_PRESS_TIME and distance < DRAG_THRESHOLD:
        emit_signal("long_press", pos)
        return

    if distance < DRAG_THRESHOLD:
        emit_signal("tap", pos)

func _on_drag(pos: Vector2) -> void:
    var distance: float = pos.distance_to(_touch_start_pos)

    if distance > DRAG_THRESHOLD:
        if not _is_dragging:
            _is_dragging = true
            emit_signal("drag_started", _touch_start_pos)

        emit_signal("dragging", _touch_start_pos, pos)
