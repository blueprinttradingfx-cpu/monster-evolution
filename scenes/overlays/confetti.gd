## Confetti.gd
## Attach to a Node2D that acts as the confetti layer.
## Call spawn_burst() from any parent script to trigger a new wave.
extends Node2D

const COLORS := [
	Color(0.420, 0.220, 0.831, 1),
	Color(0.204, 0.831, 0.600, 1),
	Color(0.992, 0.878, 0.278, 1),
	Color(0.925, 0.286, 0.600, 1),
	Color(0.655, 0.545, 0.980, 1),
]

@export var piece_count: int = 40
@export var min_duration: float = 2.0
@export var max_duration: float = 4.0

func _ready() -> void:
	spawn_burst()

func spawn_burst() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	for _i in range(piece_count):
		var rect := ColorRect.new()
		rect.size    = Vector2(8, 8)
		rect.color   = COLORS[randi() % COLORS.size()]
		rect.position = Vector2(randf() * vp_size.x, -20.0)
		add_child(rect)

		var dur := randf_range(min_duration, max_duration)
		var tw  := create_tween().set_parallel(true)
		tw.tween_property(rect, "position:y",       vp_size.y + 20.0,        dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(rect, "rotation_degrees", randf_range(0.0, 720.0), dur)
		tw.tween_property(rect, "modulate:a",       0.0,                     dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(rect.queue_free)
