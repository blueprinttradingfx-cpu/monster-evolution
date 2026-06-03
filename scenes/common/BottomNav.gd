extends Control
class_name BottomNav

signal tab_changed(tab: String)

var play_nav: PanelContainer
var minigames_nav: PanelContainer
var collection_nav: PanelContainer
var shop_nav: PanelContainer

var navs: Dictionary = {}
var active_style: StyleBoxFlat

func _ready():
	print("[BottomNav] _ready() called")
	play_nav = _find_nav_panel("PlayNav")
	minigames_nav = _find_nav_panel("MinigamesNav")
	collection_nav = _find_nav_panel("CollectionNav")
	shop_nav = _find_nav_panel("ShopNav")
	if not play_nav or not minigames_nav or not collection_nav or not shop_nav:
		push_warning("BottomNav: one or more nav nodes are missing")
		return
	# Create the active style programmatically
	active_style = StyleBoxFlat.new()
	active_style.content_margin_left = 0.0
	active_style.content_margin_top = 0.0
	active_style.content_margin_right = 0.0
	active_style.content_margin_bottom = 0.0
	active_style.bg_color = Color(0.518, 0.333, 0.937, 1)
	active_style.corner_radius_top_left = 0
	active_style.corner_radius_top_right = 0
	active_style.corner_radius_bottom_right = 0
	active_style.corner_radius_bottom_left = 0

	navs = {
		"Home": play_nav,
		"Minigames": minigames_nav,
		"Collection": collection_nav,
		"Shop": shop_nav
	}
	print("[BottomNav] Navs initialized: ", navs)
	
	# Connect gui_input to each nav
	for tab_name in navs:
		var nav = navs[tab_name]
		if nav:
			print("[BottomNav] Connecting gui_input for: ", tab_name)
			nav.gui_input.connect(func(event, tn=tab_name): _on_nav_gui_input(event, tn))
	
	set_active("Home")

func _on_nav_gui_input(event: InputEvent, tab_name: String) -> void:
	print("[BottomNav] _on_nav_gui_input() called with tab_name: ", tab_name, ", event: ", event)
	if event is InputEventMouseButton and event.pressed:
		print("[BottomNav] Mouse pressed on: ", tab_name)
		tab_changed.emit(tab_name)
		match tab_name:
			"Home":
				print("[BottomNav] Calling GameState.go_to(GameState.Screen.MENU)")
				GameState.go_to(GameState.Screen.MENU)
			"Minigames":
				print("[BottomNav] Calling GameState.go_to(GameState.Screen.MINI_GAME_HUB)")
				GameState.go_to(GameState.Screen.MINI_GAME_HUB)
			"Collection":
				print("[BottomNav] Calling GameState.go_to(GameState.Screen.COLLECTION)")
				GameState.go_to(GameState.Screen.COLLECTION)
			"Shop":
				print("[BottomNav] Calling GameState.go_to(GameState.Screen.SHOP)")
				GameState.go_to(GameState.Screen.SHOP)

func set_active(tab: String) -> void:
	print("[BottomNav] set_active() called with tab: ", tab)
	for tab_name in navs:
		var nav = navs[tab_name]
		if not nav:
			continue
		if tab_name == tab:
			nav.modulate = Color(1, 1, 1, 1)
			nav.add_theme_stylebox_override("panel", active_style)
		else:
			nav.modulate = Color(1, 1, 1, 0.55)
			nav.remove_theme_stylebox_override("panel")

func _find_nav_panel(nav_name: String) -> PanelContainer:
	var node: Node = get_node_or_null("BottomNavPanel/NavHBox/%s" % nav_name)
	if node and node is PanelContainer:
		return node

	node = get_node_or_null(nav_name)
	if node and node is PanelContainer:
		return node

	var bottom_panel: Node = get_node_or_null("BottomNavPanel")
	if bottom_panel:
		node = bottom_panel.find_child(nav_name, true, false)
		if node and node is PanelContainer:
			return node

	return null
