extends Node

## Spieler-Einstellungen (Lautstärke, Vollbild, Sprache). Getrennt vom Spielstand, weil
## sie für jedes Spiel gelten und auch ohne Spielstand erhalten bleiben sollen.
## Läuft als Autoload und wendet die Werte gleich beim Start an.

const PATH := "user://settings.cfg"
# Reihenfolge beim Durchschalten im Menü.
const LANGUAGES: Array[String] = ["en", "de"]

## Etwas hat sich geändert (z. B. Vollbild per Taste), damit offene Menüs
## ihre Anzeige anpassen.
signal changed

# 0 = stumm, 1 = volle Lautstärke.
var volume: float = 0.8
var fullscreen: bool = false
# Sprache der Spieltexte. Englisch ist die Hauptsprache, Deutsch die zweite.
# Die Texte stehen in data/translations/texts.csv.
var language: String = "en"


func _ready() -> void:
	# Die Vollbild-Taste soll auch in Menüs gehen, die das Spiel pausieren.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	apply()


## Vollbild per Taste (F11 oder Alt+Enter), überall im Spiel. _input statt
## _unhandled_input: So kommt die Taste vor allen Menüs an, und Alt+Enter
## drückt nicht nebenbei auch noch einen Knopf (Enter = Bestätigen).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	apply()
	save()
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply()
	save()
	changed.emit()


func set_language(value: String) -> void:
	language = value if value in LANGUAGES else "en"
	apply()
	save()
	changed.emit()


func apply() -> void:
	# Bus 0 ist "Master", über den aller Ton läuft. Lautstärke wird dort in
	# Dezibel angegeben; linear_to_db rechnet um. Bei 0 ganz stumm schalten.
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	AudioServer.set_bus_mute(0, volume <= 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	# Alle Labels und Buttons, deren Text ein Schlüssel ist, wechseln damit
	# sofort die Sprache (Godot übersetzt sie automatisch).
	TranslationServer.set_locale(language)


func save() -> void:
	# ConfigFile schreibt eine einfache Textdatei mit Abschnitten und Werten.
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("general", "language", language)
	config.save(PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	volume = config.get_value("audio", "volume", volume)
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	language = config.get_value("general", "language", language)
