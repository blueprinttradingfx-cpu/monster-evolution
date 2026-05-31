extends Control

@onready var name_label: Label = $SafeArea/VBoxContainer/NameLabel
@onready var creature_label: Label = $SafeArea/VBoxContainer/CreatureLabel
@onready var evolution_label: Label = $SafeArea/VBoxContainer/EvolutionLabel
@onready var unlock_label: Label = $SafeArea/VBoxContainer/UnlockLabel
@onready var back_button: Button = $SafeArea/VBoxContainer/BackButton

var creature_id: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	# Use GameState.current_creature_id that was set by go_to()
	creature_id = GameState.current_creature_id
	_update_ui()

func _update_ui() -> void:
	if creature_id == "":
		return
		
	var symbols: Array = ["🥚", "🐣", "🦖", "🦕", "🐉", "🔥"]
	var creature_ids: Array = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
	var index: int = creature_ids.find(creature_id)
	if index == -1:
		index = 0
	creature_label.text = symbols[index]
	name_label.text = MergeSystem.get_creature_name(creature_id)
	
	# For MVP, just a simple stage label
	evolution_label.text = "Evolution Stage: %d" % (index +1)
	if creature_id == "egg":
		unlock_label.text = "How to unlock: Start!"
	else:
		var prev_index: int = index -1
		if prev_index >=0:
			var prev_name: String = MergeSystem.get_creature_name(creature_ids[prev_index])
			unlock_label.text = "How to unlock: Merge 2 %s" % prev_name
		else:
			unlock_label.text = ""

func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.COLLECTION)
