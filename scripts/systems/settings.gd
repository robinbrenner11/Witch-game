extends Node

## Spieler-Einstellungen (Lautstärke, Vollbild). Getrennt vom Spielstand, weil
## sie für jedes Spiel gelten und auch ohne Spielstand erhalten bleiben sollen.
## Läuft als Autoload und wendet die Werte gleich beim Start an.

const PATH := "user://settings.cfg"

# 0 = stumm, 1 = volle Lautstärke.
var volume: float = 0.8
var fullscreen: bool = false


func _ready() -> void:
	_load()
	apply()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	apply()
	save()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply()
	save()


func apply() -> void:
	# Bus 0 ist "Master", über den aller Ton läuft. Lautstärke wird dort in
	# Dezibel angegeben; linear_to_db rechnet um. Bei 0 ganz stumm schalten.
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume <= 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save() -> void:
	# ConfigFile schreibt eine einfache Textdatei mit Abschnitten und Werten.
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	volume = config.get_value("audio", "volume", volume)
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
