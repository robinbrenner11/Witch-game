extends Control

## Einstellungen (Lautstärke, Vollbild). Baustein für Titel- und Pausemenü:
## open() zeigt es, beim Schließen kommt das Signal closed.

signal closed

const VOLUME_STEP := 0.1

@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_button: Button = %FullscreenButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	hide()


func open() -> void:
	show()
	_refresh()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _on_volume_down_pressed() -> void:
	Settings.set_volume(Settings.volume - VOLUME_STEP)
	_refresh()


func _on_volume_up_pressed() -> void:
	Settings.set_volume(Settings.volume + VOLUME_STEP)
	_refresh()


func _on_fullscreen_button_pressed() -> void:
	Settings.set_fullscreen(not Settings.fullscreen)
	_refresh()


func _on_back_button_pressed() -> void:
	_close()


func _close() -> void:
	hide()
	closed.emit()


func _refresh() -> void:
	volume_value.text = "%d %%" % roundi(Settings.volume * 100)
	fullscreen_button.text = "Vollbild: an" if Settings.fullscreen else "Vollbild: aus"
