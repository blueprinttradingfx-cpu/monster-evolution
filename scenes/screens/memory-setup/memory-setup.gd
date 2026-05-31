extends Control
## MemoryChallenge.gd
## Pre-game / level preview screen.
##
## Signals:
##   game_started  – emitted when the player taps START
##
## Public vars (set before adding to scene tree or via the Inspector):
##   theme_name     : String   – e.g. "Dinosaurs"
##   grid_columns   : int      – e.g. 2
##   grid_rows      : int      – e.g. 2
##   difficulty     : String   – "Easy" | "Medium" | "Hard"

signal game_started(theme: String, columns: int, rows: int)

@export var theme_name    : String = "Dinosaurs"
@export var grid_columns  : int    = 2
@export var grid_rows     : int    = 2
@export var difficulty    : String = "Easy"

# Difficulty dot colours
const DIFF_COLOURS := {
	"Easy":   Color(0.204, 0.831, 0.600, 1.0),   # growth-green
	"Medium": Color(0.996, 0.741, 0.133, 1.0),   # amber
	"Hard":   Color(0.729, 0.102, 0.102, 1.0),   # red
}

@onready var theme_value  : Label    = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/ThemeRow/ThemeInfo/ThemeValue
@onready var grid_value   : Label    = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/GridSizeCard/GridSizeVBox/GridSizeValue
@onready var diff_dot     : ColorRect = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffDot
@onready var diff_value   : Label    = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffValue
@onready var start_button : Button   = $BottomArea/StartButton

# Face-down preview cards – pulse on click (mirrors JS micro-interaction)
@onready var face_down_cards : Array[PanelContainer] = [
	$ScrollContainer/ContentVBox/PreviewSection/BoardGridContainer/BoardGrid/PreviewCard2,
	$ScrollContainer/ContentVBox/PreviewSection/BoardGridContainer/BoardGrid/PreviewCard3,
]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_populate_level_info()
	start_button.pressed.connect(_on_start_pressed)
	for card in face_down_cards:
		card.gui_input.connect(_on_facedown_card_input.bind(card))
	_play_hero_fade_in()

# ── Private helpers ───────────────────────────────────────────────────────────

func _populate_level_info() -> void:
	theme_value.text  = theme_name
	grid_value.text   = "%dx%d" % [grid_columns, grid_rows]
	diff_value.text   = difficulty
	diff_dot.color    = DIFF_COLOURS.get(difficulty, DIFF_COLOURS["Easy"])

func _play_hero_fade_in() -> void:
	var hero := $ScrollContainer/ContentVBox/HeroSection
	hero.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(hero, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _on_facedown_card_input(event: InputEvent, card: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed:
		_pulse(card)

func _pulse(node: Control) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2(1.06, 1.06), 0.12)
	tween.tween_property(node, "scale", Vector2(1.0,  1.0),  0.12)

func _on_start_pressed() -> void:
	# Press-down effect
	var tween := create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.96, 0.96), 0.08)
	tween.tween_property(start_button, "scale", Vector2(1.0,  1.0),  0.08)
	await tween.finished
	emit_signal("game_started", theme_name, grid_columns, grid_rows)
