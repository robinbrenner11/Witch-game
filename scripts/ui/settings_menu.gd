extends Control

## Einstellungen (Lautstärke, Vollbild, Sprache). Baustein für Titel- und Pausemenü:
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


## Schaltet zur nächsten Sprache. Der Knopf zeigt die aktuelle Sprache in
## ihrer eigenen Sprache (Language: English / Sprache: Deutsch).
func _on_language_button_pressed() -> void:
	var languages := Settings.LANGUAGES
	var next := (languages.find(Settings.language) + 1) % languages.size()
	Settings.set_language(languages[next])


func _on_back_button_pressed() -> void:
	_close()


func _close() -> void:
	hide()
	closed.emit()


func _refresh() -> void:
	volume_value.text = "%d %%" % roundi(Settings.volume * 100)
	# Schlüssel statt Text: Godot übersetzt ihn beim Anzeigen.
	fullscreen_button.text = "SETTINGS_FULLSCREEN_ON" if Settings.fullscreen else "SETTINGS_FULLSCREEN_OFF"
