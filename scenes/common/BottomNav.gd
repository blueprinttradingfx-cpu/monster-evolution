extends Control
class_name BottomNav

signal tab_changed(tab: String)
signal start_pressed()

@onready var start_button: Button = $StartButton
@onready var play_nav: PanelContainer = $BottomNavPanel/NavHBox/PlayNav
@onready var merge_nav: PanelContainer = $BottomNavPanel/NavHBox/MergeNav
@onready var collection_nav: PanelContainer = $BottomNavPanel/NavHBox/CollectionNav
@onready var shop_nav: PanelContainer = $BottomNavPanel/NavHBox/ShopNav
@onready var settings_nav: PanelContainer = $BottomNavPanel/NavHBox/SettingsNav

var navs: Dictionary = {}
var active_style: StyleBoxFlat

func _ready():
	# Create the active style programmatically
	active_style = StyleBoxFlat.new()
	active_style.content_margin_left = 16.0
	active_style.content_margin_top = 4.0
	active_style.content_margin_right = 16.0
	active_style.content_margin_bottom = 4.0
	active_style.bg_color = Color(0.518, 0.333, 0.937, 1)
	active_style.corner_radius_top_left = 12
	active_style.corner_radius_top_right = 12
	active_style.corner_radius_bottom_right = 12
	active_style.corner_radius_bottom_left = 12

	navs = {
		"play": play_nav,
		"merge": merge_nav,
		"collection": collection_nav,
		"shop": shop_nav,
		"settings": settings_nav
	}
	
	# Connect gui_input to each nav
	for tab_name in navs:
		var nav = navs[tab_name]
		nav.gui_input.connect(func(event, tn=tab_name): _on_nav_gui_input(event, tn))
	
	# Connect start button
	start_button.pressed.connect(func(): start_pressed.emit())
	
	set_active("play")

func _on_nav_gui_input(event: InputEvent, tab_name: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		tab_changed.emit(tab_name)

func set_active(tab: String) -> void:
	for tab_name in navs:
		var nav = navs[tab_name]
		if tab_name == tab:
			nav.modulate = Color(1, 1, 1, 1)
			nav.add_theme_stylebox_override("panel", active_style)
		else:
			nav.modulate = Color(1, 1, 1, 0.55)
			nav.remove_theme_stylebox_override("panel")
