extends PanelContainer

signal tab_changed(tab: String)

@onready var play = $HBoxContainer/PlayTab
@onready var merge = $HBoxContainer/MergeTab
@onready var collection = $HBoxContainer/CollectionTab
@onready var shop = $HBoxContainer/ShopTab
@onready var settings = $HBoxContainer/SettingsTab

func _ready():
	play.pressed.connect(func(): tab_changed.emit("play"))
	merge.pressed.connect(func(): tab_changed.emit("merge"))
	collection.pressed.connect(func(): tab_changed.emit("collection"))
	shop.pressed.connect(func(): tab_changed.emit("shop"))
	settings.pressed.connect(func(): tab_changed.emit("settings"))

	set_active("play")

func set_active(tab: String) -> void:
	for b in $HBoxContainer.get_children():
		if b is Button:
			b.button_pressed = false

	match tab:
		"play":
			play.button_pressed = true
		"merge":
			merge.button_pressed = true
		"collection":
			collection.button_pressed = true
		"shop":
			shop.button_pressed = true
		"settings":
			settings.button_pressed = true
