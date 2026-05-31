extends Control

@onready var top_appbar: TopAppBar = $TopAppBar
@onready var bottom_nav: BottomNav = $BottomNav
@onready var watch_now_btn: Button = $MainLayout/ScrollContainer/ContentVBox/FreeBonusSection/FreeBonusCard/FreeBonusHBox/FreeBonusTextVBox/WatchNowBtn
@onready var golden_pass_btn: Button = $MainLayout/ScrollContainer/ContentVBox/PremiumSection/PremiumVBox/GoldenPassCard/GoldenPassHBox/GoldenPassBuyBtn
@onready var purchase_popup: AcceptDialog = $PurchasePopup
@onready var dino_buy_btn: Button = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/DinoCard/DinoCardVBox/DinoPriceHBox/DinoBuyBtn
@onready var space_buy_btn: Button = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/SpaceCard/SpaceCardVBox/SpacePriceHBox/SpaceBuyBtn
@onready var jungle_buy_btn: Button = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/JungleCard/JungleCardVBox/JunglePriceHBox/JungleBuyBtn
@onready var fire_dragon_btn: Button = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FireDragonCard/FireDragonVBox/FireDragonBuyBtn
@onready var frost_blob_btn: Button = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FrostBlobCard/FrostBlobVBox/FrostBlobBuyBtn
@onready var zapling_btn: Button = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/ZaplingCard/ZaplingVBox/ZaplingBuyBtn
@onready var gloom_spirit_btn: Button = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/GloomSpiritCard/GloomSpiritVBox/GloomSpiritBuyBtn
@onready var dino_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/DinoCard/DinoCardVBox/DinoPreview
@onready var space_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/SpaceCard/SpaceCardVBox/SpacePreview
@onready var jungle_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/JungleCard/JungleCardVBox/JunglePreview
@onready var free_bonus_card: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/FreeBonusSection/FreeBonusCard
@onready var golden_pass_icon_panel: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/PremiumSection/PremiumVBox/GoldenPassCard/GoldenPassHBox/GoldenPassIcon
@onready var rare_badge_1: Label = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FireDragonCard/FireDragonVBox/FireDragonPreview/RareBadge1
@onready var epic_badge: Label = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FrostBlobCard/FrostBlobVBox/FrostBlobPreview/EpicBadge
@onready var rare_badge_2: Label = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/GloomSpiritCard/GloomSpiritVBox/GloomSpiritPreview/RareBadge2
@onready var fire_dragon_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FireDragonCard/FireDragonVBox/FireDragonPreview
@onready var frost_blob_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FrostBlobCard/FrostBlobVBox/FrostBlobPreview
@onready var zapling_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/ZaplingCard/ZaplingVBox/ZaplingPreview
@onready var gloom_spirit_preview: PanelContainer = $MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/GloomSpiritCard/GloomSpiritVBox/GloomSpiritPreview

const CARD_THEMES: Array[Dictionary] = [
	{"id": "dino", "name": "Dino Pack", "price": 500, "emoji": "🦕"},
	{"id": "space", "name": "Space Pack", "price": 800, "emoji": "🚀"},
	{"id": "jungle", "name": "Jungle Pack", "price": 650, "emoji": "🌿"},
]

const CREATURE_SKINS: Array[Dictionary] = [
	{"id": "fire_dragon", "name": "Fire Dragon", "price": 1500, "emoji": "🐉", "rarity": "RARE"},
	{"id": "frost_blob", "name": "Frost Blob", "price": 2200, "emoji": "🧊", "rarity": "EPIC"},
	{"id": "zapling", "name": "Zapling", "price": 1200, "emoji": "⚡", "rarity": ""},
	{"id": "gloom_spirit", "name": "Gloom Spirit", "price": 1800, "emoji": "👻", "rarity": "RARE"},
]

const RARITY_COLORS: Dictionary = {
	"RARE": Color(0.925, 0.286, 0.6, 1.0),
	"EPIC": Color(0.42, 0.22, 0.831, 1.0),
}

var float_targets: Array[Label] = []

func _ready():
	_apply_all_styles()
	_connect_signals()
	_refresh_currency_display()
	_collect_float_targets()
	bottom_nav.set_active("shop")
	bottom_nav.start_button.visible = false

func _process(delta: float):
	if float_targets.is_empty():
		return
	
	var time = Time.get_ticks_msec() / 1000.0
	for i in range(float_targets.size()):
		var target = float_targets[i]
		if not is_instance_valid(target):
			continue
		target.position.y = sin(time * 2.0 + i) * 5.0

func _connect_signals():
	watch_now_btn.pressed.connect(_on_watch_now_pressed)
	golden_pass_btn.pressed.connect(_on_golden_pass_pressed)
	dino_buy_btn.pressed.connect(func(): _on_theme_buy("dino"))
	space_buy_btn.pressed.connect(func(): _on_theme_buy("space"))
	jungle_buy_btn.pressed.connect(func(): _on_theme_buy("jungle"))
	fire_dragon_btn.pressed.connect(func(): _on_skin_buy("fire_dragon"))
	frost_blob_btn.pressed.connect(func(): _on_skin_buy("frost_blob"))
	zapling_btn.pressed.connect(func(): _on_skin_buy("zapling"))
	gloom_spirit_btn.pressed.connect(func(): _on_skin_buy("gloom_spirit"))
	bottom_nav.tab_changed.connect(_on_tab_pressed)

func _on_watch_now_pressed():
	_show_popup("📺 Loading ad...")

func _on_theme_buy(theme_id: String):
	var data: Dictionary = CARD_THEMES.filter(func(d): return d["id"] == theme_id).front()
	_attempt_purchase(data["id"], data["name"], data["price"])

func _on_skin_buy(skin_id: String):
	var data: Dictionary = CREATURE_SKINS.filter(func(d): return d["id"] == skin_id).front()
	_attempt_purchase(data["id"], data["name"], data["price"])

func _on_golden_pass_pressed():
	_show_popup("💳 Redirecting to store for Golden Pass ($4.99)...")

func _attempt_purchase(item_id: String, item_name: String, price: int):
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	
	if coins >= price:
		SaveSystem.add_coins(-price)
		SaveSystem.save_game()
		_refresh_currency_display()
		_show_popup("✅ Purchased %s!" % item_name)
	else:
		_show_popup("❌ Not enough coins!\nYou need %d 🪙 but only have %d." % [price, coins])

func _refresh_currency_display():
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	top_appbar.set_coins(coins)
	top_appbar.set_eggs(eggs)

func _show_popup(message: String):
	purchase_popup.dialog_text = message
	purchase_popup.popup_centered()

func _collect_float_targets():
	var paths: Array[String] = [
		"MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/DinoCard/DinoCardVBox/DinoPriceHBox/DinoPriceLabel",
		"MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/SpaceCard/SpaceCardVBox/SpacePriceHBox/SpacePriceLabel",
		"MainLayout/ScrollContainer/ContentVBox/CardThemesSection/CardThemesVBox/ThemeScroll/ThemeHBox/JungleCard/JungleCardVBox/JunglePriceHBox/JunglePriceLabel",
	]
	for p in paths:
		var node: Label = get_node_or_null(p)
		if node:
			float_targets.append(node)

func _apply_all_styles():
	_style_free_bonus_card()
	_style_theme_previews()
	_style_skin_cards()
	_style_skin_buy_buttons()
	_style_golden_pass()
	_style_badge_labels()

func _style_free_bonus_card():
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.204, 0.827, 0.6, 1.0)
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	normal.border_color = Color(0.176, 0.176, 0.176, 1.0)
	normal.corner_radius_top_left = 32
	normal.corner_radius_top_right = 32
	normal.corner_radius_bottom_left = 32
	normal.corner_radius_bottom_right = 32
	normal.shadow_color = Color(0.176, 0.176, 0.176, 1.0)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 4)
	free_bonus_card.add_theme_stylebox_override("panel", normal)
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(1, 1, 1, 1)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(0.176, 0.176, 0.176, 1.0)
	btn_normal.corner_radius_top_left = 9999
	btn_normal.corner_radius_top_right = 9999
	btn_normal.corner_radius_bottom_left = 9999
	btn_normal.corner_radius_bottom_right = 9999
	watch_now_btn.add_theme_stylebox_override("normal", btn_normal)
	watch_now_btn.add_theme_stylebox_override("hover", btn_normal)
	watch_now_btn.add_theme_stylebox_override("pressed", btn_normal)
	watch_now_btn.add_theme_color_override("font_color", Color(0.0, 0.424, 0.286, 1.0))

func _style_theme_previews():
	var bg_colors: Array[Color] = [
		Color(0.584, 0.431, 0.0, 1.0),
		Color(0.518, 0.333, 0.937, 1.0),
		Color(0.424, 0.973, 0.733, 1.0),
	]
	var previews: Array = [dino_preview, space_preview, jungle_preview]
	for i in range(previews.size()):
		var prev: PanelContainer = previews[i]
		var s = StyleBoxFlat.new()
		s.bg_color = bg_colors[i]
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = Color(0.176, 0.176, 0.176, 1.0)
		s.corner_radius_top_left = 12
		s.corner_radius_top_right = 12
		s.corner_radius_bottom_left = 12
		s.corner_radius_bottom_right = 12
		prev.add_theme_stylebox_override("panel", s)
	
	var cards: Array = [dino_preview.get_parent().get_parent(), space_preview.get_parent().get_parent(), jungle_preview.get_parent().get_parent()]
	for card in cards:
		_apply_card_style(card, Color(1, 1, 1, 1), 24)
	
	for btn in [dino_buy_btn, space_buy_btn, jungle_buy_btn]:
		_apply_primary_button(btn)

func _style_skin_cards():
	var skin_cards: Array = [
		$MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FireDragonCard,
		$MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/FrostBlobCard,
		$MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/ZaplingCard,
		$MainLayout/ScrollContainer/ContentVBox/SkinsSection/SkinsVBox/SkinsGrid/GloomSpiritCard,
	]
	for card in skin_cards:
		_apply_card_style(card, Color(0.953, 0.957, 0.961, 1), 32)
	
	var previews: Array = [fire_dragon_preview, frost_blob_preview, zapling_preview, gloom_spirit_preview]
	for preview in previews:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(1, 1, 1, 1)
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = Color(0.176, 0.176, 0.176, 1.0)
		s.corner_radius_top_left = 16
		s.corner_radius_top_right = 16
		s.corner_radius_bottom_left = 16
		s.corner_radius_bottom_right = 16
		preview.add_theme_stylebox_override("panel", s)

func _style_skin_buy_buttons():
	for btn in [fire_dragon_btn, frost_blob_btn, zapling_btn, gloom_spirit_btn]:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.992, 0.878, 0.278, 1.0)
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = Color(0.176, 0.176, 0.176, 1.0)
		s.corner_radius_top_left = 12
		s.corner_radius_top_right = 12
		s.corner_radius_bottom_left = 12
		s.corner_radius_bottom_right = 12
		s.shadow_color = Color(0.176, 0.176, 0.176, 1.0)
		s.shadow_size = 4
		s.shadow_offset = Vector2(0, 4)
		var pressed = s.duplicate() as StyleBoxFlat
		pressed.shadow_size = 0
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("hover", s)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Color(0.361, 0.263, 0.0, 1.0))

func _style_golden_pass():
	_apply_card_style($MainLayout/ScrollContainer/ContentVBox/PremiumSection/PremiumVBox/GoldenPassCard, Color(1, 1, 1, 1), 32)
	
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.518, 0.333, 0.937, 1.0)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.176, 0.176, 0.176, 1.0)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	golden_pass_icon_panel.add_theme_stylebox_override("panel", s)
	
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.204, 0.827, 0.6, 1.0)
	bs.border_width_left = 2
	bs.border_width_right = 2
	bs.border_width_top = 2
	bs.border_width_bottom = 2
	bs.border_color = Color(0.176, 0.176, 0.176, 1.0)
	bs.corner_radius_top_left = 12
	bs.corner_radius_top_right = 12
	bs.corner_radius_bottom_left = 12
	bs.corner_radius_bottom_right = 12
	bs.shadow_color = Color(0.176, 0.176, 0.176, 1.0)
	bs.shadow_size = 4
	bs.shadow_offset = Vector2(0, 4)
	var pressed = bs.duplicate() as StyleBoxFlat
	pressed.shadow_size = 0
	golden_pass_btn.add_theme_stylebox_override("normal", bs)
	golden_pass_btn.add_theme_stylebox_override("hover", bs)
	golden_pass_btn.add_theme_stylebox_override("pressed", pressed)
	golden_pass_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))

func _style_badge_labels():
	var badge_data = [
		[rare_badge_1, "RARE"],
		[epic_badge, "EPIC"],
		[rare_badge_2, "RARE"],
	]
	for pair in badge_data:
		var label: Label = pair[0]
		var rarity: String = pair[1]
		if not label:
			continue
		var color = RARITY_COLORS.get(rarity, Color(0.5, 0.5, 0.5, 1.0))
		var bg := ColorRect.new()
		bg.color = color
		bg.z_index = -1
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_sibling(bg)
		await get_tree().process_frame
		bg.position = label.position
		bg.size = label.size + Vector2(4, 2)
		bg.position -= Vector2(2, 1)

func _apply_card_style(node: PanelContainer, bg: Color, corner: int):
	if not node:
		return
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 4
	s.border_width_right = 4
	s.border_width_top = 4
	s.border_width_bottom = 4
	s.border_color = Color(0.176, 0.176, 0.176, 1.0)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.shadow_color = Color(0.176, 0.176, 0.176, 1.0)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 4)
	node.add_theme_stylebox_override("panel", s)

func _apply_primary_button(btn: Button):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.42, 0.22, 0.831, 1.0)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.176, 0.176, 0.176, 1.0)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.shadow_color = Color(0.176, 0.176, 0.176, 1.0)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 4)
	var pressed = s.duplicate() as StyleBoxFlat
	pressed.shadow_size = 0
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))

func _on_tab_pressed(tab_name: String):
	bottom_nav.set_active(tab_name)
	match tab_name:
		"play":
			GameState.go_to(GameState.Screen.MENU)
		"merge":
			GameState.go_to(GameState.Screen.MERGE)
		"collection":
			GameState.go_to(GameState.Screen.COLLECTION)
		"shop":
			GameState.go_to(GameState.Screen.SHOP)
		"settings":
			GameState.go_to(GameState.Screen.SETTINGS)
