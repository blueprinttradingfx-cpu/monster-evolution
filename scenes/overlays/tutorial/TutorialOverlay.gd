extends CanvasLayer
## TutorialOverlay.gd
## Visual guide for onboarding steps.

@onready var dimmer: ColorRect = %Dimmer
@onready var label: Label = %InstructionLabel
@onready var spotlight: ColorRect = %Spotlight

func _ready() -> void:
	hide_all()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			# If no spotlight is shown, block everything
			if not spotlight.visible:
				get_viewport().set_input_as_handled()
				return

			# Use the global Rect2 for the check
			var spotlight_rect = spotlight.get_global_rect()

			if spotlight_rect.has_point(event.position):
				# ALLOW the click to pass through to the button below
				print("[Tutorial] Input passed through spotlight at ", event.position, " rect: ", spotlight_rect)
				return
			else:
				# BLOCK the click from hitting anything else
				print("[Tutorial] Input blocked by dimmer at ", event.position, " rect: ", spotlight_rect)
				get_viewport().set_input_as_handled()

func highlight_node(target: Control) -> void:
	if not target:
		hide_all()
		return

	show()
	# Show dimmer first to ensure correct blending order if needed
	dimmer.show()
	spotlight.show()

	# Wait a frame to ensure global positions are updated
	await get_tree().process_frame
	if not is_instance_valid(target) or not target.is_inside_tree():
		return

	# Calculate spotlight position and size
	var rect = target.get_global_rect()

	# Use a separate Tweener or just set values if you want it instant
	spotlight.global_position = rect.position
	spotlight.size = rect.size

	# Optional: add a small padding
	spotlight.global_position -= Vector2(8, 8)
	spotlight.size += Vector2(16, 16)

	# Ensure spotlight is ALWAYS white for the Subtract blend mode to work
	spotlight.color = Color.WHITE

	# Move instruction label based on target position
	if spotlight.global_position.y > get_viewport().get_visible_rect().size.y / 2:
		# Target is in bottom half, move label to top
		label.anchor_top = 0
		label.anchor_bottom = 0
		label.offset_top = 100
		label.offset_bottom = 300
	else:
		# Target is in top half, move label to bottom
		label.anchor_top = 1
		label.anchor_bottom = 1
		label.offset_top = -300
		label.offset_bottom = -100

	print("[Tutorial] Highlighting node: ", target.name, " at rect: ", spotlight.get_global_rect())

func set_text(text: String) -> void:
	show()
	label.text = text
	label.show()

func hide_all() -> void:
	dimmer.hide()
	spotlight.hide()
	label.hide()
	hide()
