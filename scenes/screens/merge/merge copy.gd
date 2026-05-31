extends Control
## MergeScreen.gd
## Merge tab: two merge slots, inventory grid, MERGE button.
##
## Signals:
##   merge_completed(result_id)  – emitted after a successful merge
##
## How selection works:
##   Tap an inventory slot  → assigns it to Slot1 or Slot2 in order.
##   Tap an already-selected slot → deselects it.
##   When both slots are filled → MERGE button becomes active.
##   Tapping MERGE → plays sparkle burst, emits merge_completed.

signal merge_completed(result_id: String)

# ── Node references ──────────────────────────────────────────
@onready var slot1          : PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot1
@onready var slot1_label    : Label          = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot1/Slot1Monster
@onready var slot2          : PanelContainer = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot2
@onready var slot2_label    : Label          = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/SlotsRow/Slot2/Slot2Empty
@onready var preview_label  : Label          = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/PreviewBox/PreviewVBox/PreviewLabel
@onready var preview_icon   : Label          = $ScrollContainer/ContentVBox/MergeAreaCard/MergeAreaVBox/PreviewBox/PreviewVBox/PreviewIcon
@onready var merge_button   : Button         = $ScrollContainer/ContentVBox/MergeButton
@onready var inv_grid       : GridContainer  = $ScrollContainer/ContentVBox/InventorySection/InventoryGrid

# ── State ────────────────────────────────────────────────────
# Index of inventory slot assigned to merge slot 1 / 2 (-1 = empty)
var _slot1_inv_idx : int = -1
var _slot2_inv_idx : int = -1

# Breathing tween reference (so we can stop it when slot is replaced)
var _breathe_tween : Tween = null
var _pulse_tween   : Tween = null

# ── Lifecycle ────────────────────────────────────────────────
func _ready() -> void:
	merge_button.pressed.connect(_on_merge_pressed)
	_wire_inventory_slots()
	_start_breathing(slot1)
	_start_pulsing(slot2)
	_update_merge_button()

# ── Animation helpers ────────────────────────────────────────
func _start_breathing(node: Control) -> void:
	if _breathe_tween:
		_breathe_tween.kill()
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_tween.tween_property(node, "scale", Vector2(1.03, 1.03), 1.5)
	_breathe_tween.tween_property(node, "scale", Vector2(1.0,  1.0),  1.5)

func _start_pulsing(node: Control) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(node, "modulate:a", 0.5, 1.0)
	_pulse_tween.tween_property(node, "modulate:a", 1.0, 1.0)

func _press_bounce(node: Control) -> void:
	var t := create_tween()
	t.tween_property(node, "scale", Vector2(0.94, 0.94), 0.08)
	t.tween_property(node, "scale", Vector2(1.0,  1.0),  0.10)

func _sparkle_burst() -> void:
	# Spawn a large ✨ label at screen centre that pings out
	var lbl := Label.new()
	lbl.text = "✨"
	lbl.theme_override_font_sizes = {}            # use default
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.pivot_offset = lbl.size / 2.0
	add_child(lbl)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "scale",       Vector2(2.0, 2.0), 0.6).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a",  0.0,               0.6).set_ease(Tween.EASE_IN)
	await t.finished
	lbl.queue_free()

# ── Inventory wiring ─────────────────────────────────────────
func _wire_inventory_slots() -> void:
	for i in inv_grid.get_child_count():
		var slot : Control = inv_grid.get_child(i)
		slot.gui_input.connect(_on_inv_slot_input.bind(i))

func _on_inv_slot_input(event: InputEvent, idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var slot_node : Control = inv_grid.get_child(idx)
	# Deselect if already selected
	if idx == _slot1_inv_idx:
		_slot1_inv_idx = -1
		_refresh_slot_visuals()
		return
	if idx == _slot2_inv_idx:
		_slot2_inv_idx = -1
		_refresh_slot_visuals()
		return
	# Assign to first empty merge slot
	if _slot1_inv_idx == -1:
		_slot1_inv_idx = idx
	elif _slot2_inv_idx == -1:
		_slot2_inv_idx = idx
	_press_bounce(slot_node)
	_refresh_slot_visuals()

func _refresh_slot_visuals() -> void:
	# Mirror inventory selection state to merge slot displays
	var s1_filled := _slot1_inv_idx != -1
	var s2_filled := _slot2_inv_idx != -1

	if s1_filled:
		var src := inv_grid.get_child(_slot1_inv_idx)
		var lbl := src.get_child(0) as Label
		slot1_label.text = lbl.text if lbl else "🟢"
	else:
		slot1_label.text = "🟢"    # default placeholder

	if s2_filled:
		var src := inv_grid.get_child(_slot2_inv_idx)
		var lbl := src.get_child(0) as Label
		slot2_label.text = lbl.text if lbl else "🧩"
		slot2_label.theme_override_colors = {}
		slot2_label.modulate.a = 1.0
	else:
		slot2_label.text = "🧩"
		slot2_label.modulate.a = 0.4

	# Highlight selected inventory slots with purple border
	for i in inv_grid.get_child_count():
		var s : PanelContainer = inv_grid.get_child(i) as PanelContainer
		if s == null:
			continue
		if i == _slot1_inv_idx or i == _slot2_inv_idx:
			s.add_theme_stylebox_override("panel", SubResource("inv_slot_selected_style") if false else _make_selected_style())
		else:
			s.remove_theme_stylebox_override("panel")

	_update_merge_button()

func _make_selected_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	s.set_border_width_all(4)
	s.border_color = Color(0.420, 0.220, 0.831, 1.0)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0.420, 0.220, 0.831, 0.5)
	s.shadow_size = 6
	s.set_content_margin_all(8)
	return s

func _update_merge_button() -> void:
	merge_button.disabled = (_slot1_inv_idx == -1 or _slot2_inv_idx == -1)

# ── Merge action ─────────────────────────────────────────────
func _on_merge_pressed() -> void:
	if merge_button.disabled:
		return
	_press_bounce(merge_button)
	await get_tree().create_timer(0.15).timeout
	await _sparkle_burst()

	# TODO: look up actual merge recipe from game data
	var result_id := "sparkle_blob"
	preview_label.text = "Merged: Sparkle Blob ✨"
	preview_icon.text = "🌟"

	# Reset slots
	_slot1_inv_idx = -1
	_slot2_inv_idx = -1
	_refresh_slot_visuals()

	emit_signal("merge_completed", result_id)
