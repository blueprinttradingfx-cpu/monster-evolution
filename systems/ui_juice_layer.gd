extends Node

func on_event(event_type: String, payload: Dictionary) -> void:
	match event_type:
		"card_flip":
			_card_flip_fx(payload)
		"match_success":
			_match_success_fx(payload)
		"match_fail":
			_match_fail_fx(payload)
		"board_complete":
			_board_complete_fx(payload)
		"reward_granted":
			_reward_granted_fx(payload)
		"merge_success":
			_merge_success_fx(payload)

func camera_pulse(intensity: float = 0.95) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(cam, "zoom", Vector2(intensity, intensity), 0.05)
	tween.tween_property(cam, "zoom", Vector2(1, 1), 0.1)

func screen_shake(intensity: float = 1.0) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return
	var offset: Vector2 = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)
	cam.offset = offset
	await get_tree().create_timer(0.05).timeout
	cam.offset = Vector2.ZERO

func pop(node: Node, scale_amount: float = 1.2) -> void:
	if not node.has_method("tween_property"):
		return
	var tween: Tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(scale_amount, scale_amount), 0.08)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.12)

func float_text(text: String, position: Vector2, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_tree().root.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 60, 0.6)
	tween.tween_property(label, "modulate:a", 0, 0.6)
	tween.tween_callback(label.queue_free)

func haptic(strength: String) -> void:
	if not OS.has_feature("mobile"):
		return
	
	match strength:
		"light":
			Input.vibrate_handheld(10)
		"medium":
			Input.vibrate_handheld(25)
		"heavy":
			Input.vibrate_handheld(60)

func _card_flip_fx(payload: Dictionary) -> void:
	pass

func _match_success_fx(payload: Dictionary) -> void:
	camera_pulse(0.97)
	haptic("light")

func _match_fail_fx(payload: Dictionary) -> void:
	screen_shake(2.0)
	haptic("light")

func _board_complete_fx(payload: Dictionary) -> void:
	camera_pulse(0.9)
	haptic("medium")

func _reward_granted_fx(payload: Dictionary) -> void:
	pass

func _merge_success_fx(payload: Dictionary) -> void:
	camera_pulse(0.9)
	screen_shake(3.0)
	haptic("medium")
