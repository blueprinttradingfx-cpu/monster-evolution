extends Control

# HatchScene - Egg hatching animation and monster reveal
# Per TICKET-14 and Screen Flow Section 6

# --- SIGNALS ---
signal hatching_complete(monsterId: String)

# --- CONSTANTS ---
const SHAKE_DURATION: float = 0.5
const CRACK_DURATION: float = 0.3
const REVEAL_DURATION: float = 0.5

# --- NODES ---
@onready var _egg_sprite: Sprite2D = $MainContent/EggContainer/EggSprite
@onready var _monster_display: MonsterDisplay = $MainContent/MonsterContainer/MonsterDisplay
@onready var _monster_name_label: Label = $MainContent/MonsterInfo/MonsterNameLabel
@onready var _species_label: Label = $MainContent/MonsterInfo/SpeciesLabel
@onready var _add_to_collection_label: Label = $MainContent/AddToCollectionLabel
@onready var _return_home_button: Button = $MainContent/ReturnHomeButton

# --- VARIABLES ---
var _current_monster_id: String = ""
var _current_owned_egg_id: String = ""
var _is_animation_playing: bool = false

func _ready() -> void:
	_connect_signals()
	_reset_scene()
	
	# For testing: start with a dino egg
	if MonsterManager:
		var eggs: Array = MonsterManager.get_owned_eggs()
		if eggs.size() > 0:
			await get_tree().process_frame
			start_hatching(eggs[0].id)
		else:
			var new_egg_id: String = MonsterManager.add_egg("dino_egg")
			await get_tree().process_frame
			start_hatching(new_egg_id)

func _connect_signals() -> void:
	_return_home_button.pressed.connect(_on_return_home_pressed)

func start_hatching(owned_egg_id: String) -> void:
	if _is_animation_playing:
		return
	
	_is_animation_playing = true
	_current_owned_egg_id = owned_egg_id
	
	# Hatch egg via MonsterManager
	if MonsterManager:
		_current_monster_id = MonsterManager.hatch_egg(owned_egg_id)
	
	# Start animation sequence
	await _play_hatch_animation()
	
	_hatching_complete()

func _get_egg_type_from_owned_id(owned_egg_id: String) -> String:
	if MonsterManager:
		var eggs: Array = MonsterManager.get_owned_eggs()
		for egg in eggs:
			if egg.id == owned_egg_id:
				return egg.eggTypeId
	return "dino_egg"

func _get_species_id_from_egg(egg_type_id: String) -> String:
	match egg_type_id:
		"dino_egg":
			return "dino"
		"slime_egg":
			return "slime"
		_:
			return "dino"

func _play_hatch_animation() -> void:
	_reset_scene()
	
	# Step 1: Egg shake
	await _play_egg_shake()
	
	# Step 2: Crack animation
	await _play_crack_animation()
	
	# Step 3: Reveal monster
	await _play_reveal_animation()

func _play_egg_shake() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Shake egg left and right
	for i in range(4):
		tween.tween_property(_egg_sprite, "rotation", deg_to_rad(5), 0.1)
		tween.tween_property(_egg_sprite, "rotation", deg_to_rad(-5), 0.1)
	
	tween.tween_property(_egg_sprite, "rotation", 0, 0.1)
	await tween.finished

func _play_crack_animation() -> void:
	var tween: Tween = create_tween()
	
	# Egg scales up slightly then down (crack effect)
	tween.tween_property(_egg_sprite, "scale", Vector2(1.1, 1.1), CRACK_DURATION / 2)
	tween.tween_property(_egg_sprite, "scale", Vector2(0.0, 0.0), CRACK_DURATION / 2)
	await tween.finished

func _play_reveal_animation() -> void:
	var tween: Tween = create_tween()
	
	# Hide egg, show monster
	_egg_sprite.visible = false
	_monster_display.visible = true
	_monster_display.modulate.a = 0.0
	_monster_display.scale = Vector2(0.5, 0.5)
	
	# Set monster data
	if _monster_display.has_method("set_monster") and _current_monster_id and MonsterManager:
		var monster_data: Dictionary = MonsterManager.get_monster(_current_monster_id)
		_monster_display.set_monster(monster_data)
	
	# Fade in and scale up
	tween.tween_property(_monster_display, "modulate:a", 1.0, REVEAL_DURATION)
	tween.tween_property(_monster_display, "scale", Vector2(1.0, 1.0), REVEAL_DURATION)
	
	await tween.finished
	
	# Show info labels
	_show_monster_info()

func _show_monster_info() -> void:
	# Get monster data
	if MonsterManager and _current_monster_id:
		var monster_data: Dictionary = MonsterManager.get_monster(_current_monster_id)
		var species_id: String = monster_data.get("speciesId", "")
		
		# Set labels
		_monster_name_label.text = "New Monster!"
		_species_label.text = species_id.capitalize()
		_add_to_collection_label.visible = true
		_return_home_button.visible = true

func _hatching_complete() -> void:
	_is_animation_playing = false
	
	# Auto-save (handled by MonsterManager)
	# Increment GameManager.totalEggsHatched (handled by MonsterManager)
	
	hatching_complete.emit(_current_monster_id)
	if GameManager:
		GameManager.complete_hatch_flow()

func _reset_scene() -> void:
	_egg_sprite.visible = true
	_egg_sprite.rotation = 0
	_egg_sprite.scale = Vector2(1.0, 1.0)
	_monster_display.visible = false
	_monster_display.modulate.a = 1.0
	_monster_display.scale = Vector2(1.0, 1.0)
	_monster_name_label.text = ""
	_species_label.text = ""
	_add_to_collection_label.visible = false
	_return_home_button.visible = false

func _on_return_home_pressed() -> void:
	# Return to home screen
	if GameManager:
		GameManager.change_screen("Home")
