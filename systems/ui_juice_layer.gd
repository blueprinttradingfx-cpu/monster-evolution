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
		"evolution_unlock":
			_evolution_unlock_fx(payload)
		"button_press":
			_button_press_fx(payload)

func camera_pulse(intensity: float = 0.95) -> void:
	if has_node("/root/PerformanceLayer") and not get_node("/root/PerformanceLayer").can_emit("camera_pulse"):
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(cam, "zoom", Vector2(intensity, intensity), 0.05)
	tween.tween_property(cam, "zoom", Vector2(1, 1), 0.1)

func screen_shake(intensity: float = 1.0, duration: float = 0.2) -> void:
	if has_node("/root/PerformanceLayer") and not get_node("/root/PerformanceLayer").can_emit("screen_shake"):
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return

	var tween = create_tween()
	var shake_count = int(duration / 0.05)

	for i in range(shake_count):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(cam, "offset", offset, 0.05)

	tween.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func pop(node: Control, scale_amount: float = 1.2) -> void:
	if not node: return

	# Ensure pivot is centered for scaling
	node.pivot_offset = node.size / 2.0

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2(scale_amount, scale_amount), 0.1)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.1)

func float_text(text: String, position: Vector2, color: Color, is_critical: bool = false) -> void:
	if not is_critical and has_node("/root/PerformanceLayer") and not get_node("/root/PerformanceLayer").can_emit("float_text"):
		return

	var label: Label = Label.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100 # Ensure it's on top

	if is_critical:
		label.add_theme_font_size_override("font_size", 48)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 8)
	else:
		label.add_theme_font_size_override("font_size", 32)

	get_tree().root.add_child(label)

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 60, 0.6)
	tween.tween_property(label, "modulate:a", 0, 0.6)
	tween.tween_callback(label.queue_free)

func haptic(strength: String) -> void:
	if not OS.has_feature("mobile"):
		return

	if has_node("/root/PerformanceLayer") and not get_node("/root/PerformanceLayer").can_emit("haptic"):
		return

	match strength:
		"light":
			Input.vibrate_handheld(10)
		"medium":
			Input.vibrate_handheld(25)
		"heavy":
			Input.vibrate_handheld(60)

func _card_flip_fx(payload: Dictionary) -> void:
	# Note: in a real project we'd pass the card node in payload
	if payload.has("node"):
		pop(payload["node"], 1.1)

func _match_success_fx(payload: Dictionary) -> void:
	camera_pulse(0.97)
	haptic("light")

	if payload.has("a_node"):
		pop(payload["a_node"], 1.15)
	if payload.has("b_node"):
		pop(payload["b_node"], 1.15)

	var vp_size = get_viewport().get_visible_rect().size
	var center = vp_size / 2.0
	float_text("MATCH!", center, Color.GREEN)

func _match_fail_fx(payload: Dictionary) -> void:
	screen_shake(5.0, 0.2)
	haptic("light")

	if payload.has("a_node"):
		_shake_node(payload["a_node"])
	if payload.has("b_node"):
		_shake_node(payload["b_node"])

func _shake_node(node: Control) -> void:
	if not node: return
	var tween = create_tween()
	var orig_pos = node.position
	for i in range(4):
		tween.tween_property(node, "position:x", orig_pos.x + 10, 0.05)
		tween.tween_property(node, "position:x", orig_pos.x - 10, 0.05)
	tween.tween_property(node, "position:x", orig_pos.x, 0.05)

func _board_complete_fx(payload: Dictionary) -> void:
	camera_pulse(0.9)
	haptic("medium")
	var vp_size = get_viewport().get_visible_rect().size
	float_text("BOARD CLEAR!", Vector2(vp_size.x / 2, vp_size.y * 0.3), Color.GOLD, true)

func _reward_granted_fx(payload: Dictionary) -> void:
	var coins = payload.get("coins", 0)
	var eggs = payload.get("eggs", 0)
	var vp_size = get_viewport().get_visible_rect().size
	var center = vp_size / 2.0

	if coins > 0:
		float_text("+%d COINS" % coins, center + Vector2(0, 50), Color.YELLOW)
	if eggs > 0:
		await get_tree().create_timer(0.2).timeout
		float_text("+%d EGGS" % eggs, center + Vector2(0, 100), Color.WHITE)

func _merge_success_fx(payload: Dictionary) -> void:
	camera_pulse(0.85)
	screen_shake(10.0, 0.3)
	haptic("heavy")
	var vp_size = get_viewport().get_visible_rect().size
	float_text("EVOLUTION!", Vector2(vp_size.x / 2, vp_size.y * 0.4), Color.CYAN, true)

func _button_press_fx(payload: Dictionary) -> void:
	if payload.has("node"):
		pop(payload["node"], 0.95) # Squish down
	haptic("light")

func _evolution_unlock_fx(payload: Dictionary) -> void:
	# 1. Slow Motion
	Engine.time_scale = 0.5

	# 2. Camera Zoom
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		var zoom_tween = create_tween()
		zoom_tween.tween_property(cam, "zoom", Vector2(1.5, 1.5), 0.4)
		zoom_tween.tween_property(cam, "zoom", Vector2(1.0, 1.0), 0.6).set_delay(0.2)

	# 3. Effects
	camera_pulse(0.7)
	screen_shake(20.0, 0.5)
	haptic("heavy")

	# 4. Impact Flash
	var vp_size = get_viewport().get_visible_rect().size
	float_text("!!! NEW MONSTER !!!", vp_size / 2.0, Color.WHITE, true)

	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1.0
