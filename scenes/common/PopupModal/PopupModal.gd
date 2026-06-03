extends Control

# PopupModal component - Reusable modal for dialogs, confirmations, and alerts
# Per UI Wireframe Section 2: Reusable Components

signal confirmed()
signal cancelled()

@onready var _dark_overlay: ColorRect = $DarkOverlay
@onready var _modal_panel: CenterContainer = $ModalPanel
@onready var _panel_background: Panel = $ModalPanel/PanelBackground
@onready var _title_label: Label = $ModalPanel/PanelBackground/VBoxContainer/TitleLabel
@onready var _message_label: Label = $ModalPanel/PanelBackground/VBoxContainer/MessageLabel
@onready var _confirm_button: Button = $ModalPanel/PanelBackground/VBoxContainer/ButtonRow/ConfirmButton
@onready var _cancel_button: Button = $ModalPanel/PanelBackground/VBoxContainer/ButtonRow

var _confirm_callback: Callable
var _cancel_callback: Callable

func _ready() -> void:
	_connect_signals()
	hide_modal()

func _connect_signals() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)

func show_modal(title: String, message: String, confirm_callback: Callable) -> void:
	_title_label.text = title
	_message_label.text = message
	_confirm_callback = confirm_callback
	_cancel_button.visible = false
	
	_show_modal()

func show_modal_with_cancel(title: String, message: String, confirm_callback: Callable, cancel_callback: Callable) -> void:
	_title_label.text = title
	_message_label.text = message
	_confirm_callback = confirm_callback
	_cancel_callback = cancel_callback
	_cancel_button.visible = true
	
	_show_modal()

func hide_modal() -> void:
	_hide_modal()

func _show_modal() -> void:
	visible = true
	
	# Dark overlay fade in
	var tween: Tween = create_tween()
	tween.tween_property(_dark_overlay, "color:a", 0.0, 0.2)
	
	# Scale up animation from center
	_modal_panel.scale = Vector2.ZERO
	var tween_scale: Tween = create_tween()
	tween_scale.tween_property(_modal_panel, "scale", Vector2.ONE, 0.2)
	tween_scale.parallel().tween_property(_panel_background, "scale", Vector2.ONE, 0.2)

func _hide_modal() -> void:
	# Scale down animation
	var tween_scale: Tween = create_tween()
	tween_scale.tween_property(_panel_background, "scale", Vector2.ZERO, 0.15)
	tween_scale.parallel().tween_property(_modal_panel, "scale", Vector2.ZERO, 0.15)
	tween_scale.tween_finished.connect(_on_hide_animation_complete)
	
	# Dark overlay fade out
	tween_scale.parallel().tween_property(_dark_overlay, "color:a", 0.0, 0.15)

func _on_hide_animation_complete() -> void:
	visible = false

func _on_confirm_pressed() -> void:
	confirmed.emit()
	hide_modal()
	
	if _confirm_callback != null and _confirm_callback.is_valid():
		_confirm_callback.call()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_modal()
	
	if _cancel_callback != null and _cancel_callback.is_valid():
		_cancel_callback.call()
