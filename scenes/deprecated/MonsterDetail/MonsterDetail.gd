extends Control

# Monster Detail Screen - Inspect a single monster with stats, cosmetics, and actions
# Per Screen Flow Section 9

signal back_requested()
signal set_active_requested(monsterId: String)
signal evolve_requested(monsterId: String)
signal rename_requested(monsterId: String)
signal cosmetic_slot_pressed(monsterId: String, slot: String)

@onready var _monster_display: Control = $SafeArea/VBoxContainer/MainContent/MonsterDisplay
@onready var _nickname_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/StatsPanel/NicknameLabel
@onready var _species_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/StatsPanel/SpeciesLabel
@onready var _stage_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/StatsPanel/StageLabel
@onready var _morph_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/StatsPanel/MorphLabel
@onready var _acquired_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/StatsPanel/AcquiredLabel
@onready var _head_slot: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/CosmeticsPanel/CosmeticSlots/HeadSlot
@onready var _face_slot: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/CosmeticsPanel/CosmeticSlots/FaceSlot
@onready var _body_slot: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/CosmeticsPanel/CosmeticSlots/BodySlot
@onready var _back_slot: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/CosmeticsPanel/CosmeticSlots/BackSlot
@onready var _evolution_panel: VBoxContainer = $SafeArea/VBoxContainer/MainContent/InfoPanel/EvolutionPanel
@onready var _next_stage_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/EvolutionPanel/NextStageLabel
@onready var _evolution_cost_label: Label = $SafeArea/VBoxContainer/MainContent/InfoPanel/EvolutionPanel/EvolutionCostLabel
@onready var _set_active_button: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/ActionButtons/SetActiveButton
@onready var _evolve_button: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/ActionButtons/EvolveButton
@onready var _rename_button: Button = $SafeArea/VBoxContainer/MainContent/InfoPanel/ActionButtons/RenameButton
@onready var _back_button: Button = $SafeArea/VBoxContainer/TopBar/BackButton

var _monster_id: String = ""

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_set_active_button.pressed.connect(_on_set_active_pressed)
	_evolve_button.pressed.connect(_on_evolve_pressed)
	_rename_button.pressed.connect(_on_rename_pressed)
	_head_slot.pressed.connect(_on_head_slot_pressed)
	_face_slot.pressed.connect(_on_face_slot_pressed)
	_body_slot.pressed.connect(_on_body_slot_pressed)
	_back_slot.pressed.connect(_on_back_slot_pressed)

func set_monster(monster_id: String) -> void:
	_monster_id = monster_id
	
	var monster_data: Dictionary = MonsterManager.get_monster(monster_id)
	
	if monster_data.is_empty():
		push_error("MonsterDetail: Monster %s not found" % monster_id)
		return
	
	# Update stats panel
	if monster_data.has("speciesId"):
		_species_label.text = "Species: %s" % monster_data.speciesId.capitalize()
	
	if monster_data.has("stageId"):
		_stage_label.text = "Stage: %s" % _get_stage_name(monster_data.stageId)
	
	if monster_data.has("morphId"):
		_morph_label.text = "Morph: %s" % monster_data.morphId.capitalize()
	else:
		_morph_label.text = "Morph: Default"
	
	if monster_data.has("nickname"):
		_nickname_label.text = "Nickname: %s" % monster_data.nickname
	else:
		_nickname_label.text = "Nickname: Monster"
	
	if monster_data.has("createdAt"):
		_acquired_label.text = "Acquired: %s" % monster_data.createdAt
	
	# Update cosmetic slots
	_update_cosmetic_slots(monster_data)
	
	# Update evolution panel
	_update_evolution_panel(monster_id)
	
	# Update monster display
	if _monster_display.has_method("set_monster"):
		_monster_display.set_monster(monster_data)

func _update_cosmetic_slots(monster_data: Dictionary) -> void:
	var cosmetics: Dictionary = {
		"head": monster_data.get("equippedHeadId", ""),
		"face": monster_data.get("equippedFaceId", ""),
		"body": monster_data.get("equippedBodyId", ""),
		"back": monster_data.get("equippedBackId", "")
	}
	
	_head_slot.text = "Head: %s" % (cosmetics.head if cosmetics.head else "None")
	_face_slot.text = "Face: %s" % (cosmetics.face if cosmetics.face else "None")
	_body_slot.text = "Body: %s" % (cosmetics.body if cosmetics.body else "None")
	_back_slot.text = "Back: %s" % (cosmetics.back if cosmetics.back else "None")

func _update_evolution_panel(monster_id: String) -> void:
	var cost: int = MonsterManager.get_evolution_cost(monster_id)
	
	if cost == 0:
		_evolution_panel.visible = false
		_evolve_button.visible = false
		return
	
	_evolution_panel.visible = true
	_evolve_button.visible = true
	
	var monster_data: Dictionary = MonsterManager.get_monster(monster_id)
	var current_stage_id: String = monster_data.get("stageId", "stage_0")
	var next_stage_id: String = _get_next_stage_id(current_stage_id)
	
	_next_stage_label.text = "Next Stage: %s" % _get_stage_name(next_stage_id)
	_evolution_cost_label.text = "Cost: %d coins" % cost

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0": return "Egg"
		"stage_1": return "Baby"
		"stage_2": return "Kid"
		"stage_3": return "Adult"
		"stage_4": return "Elder"
		_: return "?"

func _get_next_stage_id(current_stage_id: String) -> String:
	match current_stage_id:
		"stage_0": return "stage_1"
		"stage_1": return "stage_2"
		"stage_2": return "stage_3"
		"stage_3": return "stage_4"
		"stage_4": return "stage_4"
		_: return "stage_1"

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_set_active_pressed() -> void:
	if _monster_id != "":
		MonsterManager.set_active_monster(_monster_id)
		set_active_requested.emit(_monster_id)

func _on_evolve_pressed() -> void:
	if _monster_id != "":
		evolve_requested.emit(_monster_id)

func _on_rename_pressed() -> void:
	if _monster_id != "":
		rename_requested.emit(_monster_id)

func _on_head_slot_pressed() -> void:
	if _monster_id != "":
		cosmetic_slot_pressed.emit(_monster_id, "head")

func _on_face_slot_pressed() -> void:
	if _monster_id != "":
		cosmetic_slot_pressed.emit(_monster_id, "face")

func _on_body_slot_pressed() -> void:
	if _monster_id != "":
		cosmetic_slot_pressed.emit(_monster_id, "body")

func _on_back_slot_pressed() -> void:
	if _monster_id != "":
		cosmetic_slot_pressed.emit(_monster_id, "back")
