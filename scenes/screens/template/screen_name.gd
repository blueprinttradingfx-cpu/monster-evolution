## screen_name.gd
## ============================================================
## Rename this file to match your screen (e.g. shop.gd).
## Replace "ScreenName" with the PascalCase screen name.
## ============================================================
class_name ScreenName
extends Control

# ── Node references ─────────────────────────────────────────
# Use %UniqueNodeName syntax (the % prefix) so renames in the
# editor don't silently break your @onready assignments.
@onready var top_app_bar: Control  = %TopAppBar
@onready var bottom_nav: Control   = %BottomNav
@onready var main: VBoxContainer   = %Main

# ── Lifecycle ───────────────────────────────────────────────
func _ready() -> void:
	_connect_signals()
	_refresh_ui()


# ── Private ─────────────────────────────────────────────────
func _connect_signals() -> void:
	# Connect your buttons and custom signals here.
	# Example:
	# %PlayButton.pressed.connect(_on_play_pressed)
	pass


func _refresh_ui() -> void:
	# Pull data from your game state / autoload and update labels.
	# Keep all display logic here so _ready() stays clean.
	pass


# ── Signal handlers ─────────────────────────────────────────
# Name handlers _on_NodeName_signal_name for clarity.
# Example:
# func _on_play_pressed() -> void:
# 	SceneManager.go_to("res://scenes/screens/battle/battle.tscn")
