extends Control

@onready var continue_button: Button = $CanvasLayer/Panel/VBoxContainer/ContinueButton
@onready var name_label: Label = $CanvasLayer/Panel/VBoxContainer/NameLabel
@onready var creature_reveal: Label = $CanvasLayer/Panel/VBoxContainer/CreatureReveal

func _ready() -> void:
	var rewards: Dictionary = GameState.session_rewards
	var creature_id: String = rewards.get("merged_creature", "")
	var symbols: Array[String] = ["🦖", "🦕", "🐣", "🥚", "🦎", "🐊"]
	var creature_ids: Array[String] = ["egg", "baby_dino", "raptor", "t_rex", "dragon", "lava_dragon"]
	var idx: int = creature_ids.find(creature_id)
	if idx == -1:
		idx = creature_id.hash() % symbols.size()
	creature_reveal.text = symbols[idx]
	name_label.text = MergeSystem.get_creature_name(creature_id)
	continue_button.pressed.connect(_on_continue_pressed)
	_play_reveal_animation()

func _play_reveal_animation() -> void:
	creature_reveal.scale = Vector2(0.5, 0.5)
	creature_reveal.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(creature_reveal, "scale", Vector2(1, 1), 0.5)
	tween.tween_property(creature_reveal, "modulate:a", 1.0, 0.5)

func _on_continue_pressed() -> void:
	NavigationManager.pop_overlay()
