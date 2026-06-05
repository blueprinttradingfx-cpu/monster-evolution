extends PanelContainer
class_name BottomNav

signal tab_changed(tab: String)

var play_nav: Button
var minigames_nav: Button
var collection_nav: Button
var shop_nav: Button

var navs: Dictionary = {}

func _ready():
	print("[BottomNav] _ready() called")
	play_nav = _find_nav_button("PlayNav")
	minigames_nav = _find_nav_button("MinigamesNav")
	collection_nav = _find_nav_button("CollectionNav")
	shop_nav = _find_nav_button("ShopNav")
	if not play_nav or not minigames_nav or not collection_nav or not shop_nav:
		push_warning("BottomNav: one or more nav nodes are missing")
		return

	navs = {
		"Home": play_nav,
		"Minigames": minigames_nav,
		"Collection": collection_nav,
		"Shop": shop_nav
	}
	print("[BottomNav] Navs initialized: ", navs)
	
	# Connect pressed to each nav
	for tab_name in navs:
		var nav = navs[tab_name]
		if nav:
			print("[BottomNav] Connecting pressed for: ", tab_name)
			nav.pressed.connect(func(): _on_nav_pressed(tab_name))
	
	set_active("Home")

func _on_nav_pressed(tab_name: String) -> void:
	print("[BottomNav] _on_nav_pressed() called with tab_name: ", tab_name)
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
		else:
			nav.modulate = Color(1, 1, 1, 0.5)

func _find_nav_button(nav_name: String) -> Button:
	var node: Node = get_node_or_null("NavHBox/%s" % nav_name)
	if node and node is Button:
		return node

	node = get_node_or_null(nav_name)
	if node and node is Button:
		return node

	var nav_hbox: Node = get_node_or_null("NavHBox")
	if nav_hbox:
		node = nav_hbox.find_child(nav_name, true, false)
		if node and node is Button:
			return node

	return null
