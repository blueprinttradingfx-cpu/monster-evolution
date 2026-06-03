extends Control

# EvolutionConfirmation Screen - Confirm monster evolution
# Per TICKET-17 and Screen Flow Section 10

# --- SIGNALS ---
signal evolution_confirmed(monsterId: String)
signal evolution_cancelled()

# --- NODES ---
@onready var _current_monster_display: Control = $MainContent/MonsterComparison/CurrentMonsterContainer/MonsterDisplay
@onready var _next_monster_display: Control = $MainContent/MonsterComparison/NextMonsterContainer/MonsterDisplay
@onready var _current_stage_label: Label = $MainContent/MonsterComparison/CurrentMonsterContainer/StageLabel
@onready var _next_stage_label: Label = $MainContent/MonsterComparison/NextMonsterContainer/StageLabel
@onready var _cost_label: Label = $MainContent/CostDisplay/CostLabel
@onready var _coins_label: Label = $MainContent/CostDisplay/CoinsLabel
@onready var _warning_label: Label = $MainContent/CostDisplay/WarningLabel
@onready var _confirm_button: Button = $MainContent/ButtonContainer/ConfirmButton
@onready var _cancel_button: Button = $MainContent/ButtonContainer/CancelButton
@onready var _success_popup: Control = $SuccessPopup
@onready var _evolution_animation_overlay: Control = $EvolutionAnimationOverlay
@onready var _morph_selection_ui: Control = $MorphSelectionUI

# --- VARIABLES ---
var _monster_id: String = ""
var _evolution_cost: int = 0
var _is_animating: bool = false

func _ready() -> void:
	_connect_signals()
	_reset_ui()
	# For testing, use the first monster if available
	if MonsterManager:
		var monster_ids = MonsterManager.get_owned_monster_ids()
		if monster_ids.size() > 0:
			open(monster_ids[0])

func _connect_signals() -> void:
	if _confirm_button:
		_confirm_button.pressed.connect(_on_confirm_pressed)
	if _cancel_button:
		_cancel_button.pressed.connect(_on_cancel_pressed)
	if EconomyManager:
		EconomyManager.coins_changed.connect(_on_coins_changed)
	if _morph_selection_ui:
		_morph_selection_ui.morph_selected.connect(_on_morph_selected)
		_morph_selection_ui.selection_cancelled.connect(_on_morph_selection_cancelled)
		_morph_selection_ui.visible = false

func _reset_ui() -> void:
	_warning_label.visible = false
	_confirm_button.disabled = false
	_success_popup.visible = false
	_evolution_animation_overlay.visible = false

func open(monster_id: String) -> void:
	_monster_id = monster_id
	_load_monster_data()
	_update_ui()

func _load_monster_data() -> void:
	if not MonsterManager or not _monster_id:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	# Display current stage
	if _current_monster_display and _current_monster_display.has_method("set_monster"):
		_current_monster_display.set_monster(monster_data)
	
	_current_stage_label.text = _get_stage_name(monster_data.get("stageId", "stage_1"))
	
	# Get cost and next stage
	_evolution_cost = MonsterManager.get_evolution_cost(_monster_id)
	if _evolution_cost > 0:
		# Create a copy of monster data for next stage preview
		var next_monster_data: Dictionary = monster_data.duplicate()
		var current_stage_id: String = next_monster_data.get("stageId", "stage_1")
		var next_stage_id: String = _get_next_stage_id(current_stage_id)
		next_monster_data["stageId"] = next_stage_id
		
		if _next_monster_display and _next_monster_display.has_method("set_monster"):
			_next_monster_display.set_monster(next_monster_data)
		
		_next_stage_label.text = _get_stage_name(next_stage_id)
	else:
		_next_stage_label.text = "Max Stage"
		if _next_monster_display:
			_next_monster_display.visible = false

func _update_ui() -> void:
	_cost_label.text = "Evolution Cost: %d coins" % _evolution_cost
	
	if EconomyManager:
		_coins_label.text = "Your Coins: %d" % EconomyManager.get_coins()
		_validate_coins()

func _validate_coins() -> void:
	if not EconomyManager:
		return
	
	var can_afford: bool = EconomyManager.can_afford(_evolution_cost)
	_confirm_button.disabled = not can_afford or _evolution_cost == 0
	_warning_label.visible = not can_afford and _evolution_cost > 0

func _on_coins_changed(new_amount: int) -> void:
	_coins_label.text = "Your Coins: %d" % new_amount
	_validate_coins()

func _on_confirm_pressed() -> void:
	if _is_animating or _evolution_cost == 0:
		return
	
	if not EconomyManager or not MonsterManager:
		return
	
	if not EconomyManager.can_afford(_evolution_cost):
		_show_insufficient_coins_popup()
		return
	
	# Check if we need to show morph selection
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var current_stage_id: String = monster_data.get("stageId", "stage_1")
	var stage_num: int = _get_stage_number(current_stage_id)
	
	# Show morph selection if evolving from Adult (stage 3) to Elder (stage 4)
	if stage_num == 3:
		_morph_selection_ui.open(_monster_id)
	else:
		# Otherwise, just evolve normally
		_play_evolution_animation()

func _play_evolution_animation() -> void:
	_is_animating = true
	_evolution_animation_overlay.visible = true
	
	# Simple scale and glow animation
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Scale up
	tween.tween_property(_evolution_animation_overlay, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(_evolution_animation_overlay, "modulate:a", 0.0, 0.2)
	tween.set_parallel(true)
	
	await tween.finished
	
	# Execute evolution
	var success: bool = MonsterManager.evolve_monster(_monster_id)
	if success:
		_play_success_animation()
		evolution_confirmed.emit(_monster_id)
	else:
		_close()

func _play_success_animation() -> void:
	_success_popup.visible = true
	await get_tree().create_timer(2.0).timeout
	_close()

func _show_insufficient_coins_popup() -> void:
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = "Not Enough Coins"
	popup.dialog_text = "You need %d coins to evolve!" % _evolution_cost
	add_child(popup)
	popup.popup_centered()

func _on_cancel_pressed() -> void:
	evolution_cancelled.emit()
	_close()

func _on_morph_selected(morph_id: String) -> void:
	print("Morph selected: %s" % morph_id)
	_play_evolution_animation()

func _on_morph_selection_cancelled() -> void:
	print("Morph selection cancelled")
	_morph_selection_ui.visible = false

func _close() -> void:
	# Return to previous screen
	if GameManager:
		GameManager.return_to_flow_origin()

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0":
			return "Egg"
		"stage_1":
			return "Baby"
		"stage_2":
			return "Kid"
		"stage_3":
			return "Adult"
		"stage_4":
			return "Elder"
		_:
			return "Unknown"

func _get_next_stage_id(current_stage_id: String) -> String:
	var stage_number: int = _get_stage_number(current_stage_id)
	var next_stage: int = stage_number + 1
	if next_stage > 4:
		return current_stage_id
	return "stage_%d" % next_stage

func _get_stage_number(stage_id: String) -> int:
	match stage_id:
		"stage_0":
			return 0
		"stage_1":
			return 1
		"stage_2":
			return 2
		"stage_3":
			return 3
		"stage_4":
			return 4
		_:
			return 0
