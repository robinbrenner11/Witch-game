extends Node

## Speichert und lädt den Spielstand. Gespeichert wird beim Schlafen und über
## das Pausemenü; geladen wird über "Fortsetzen" im Titelmenü.
##
## Jedes System liefert selbst, was von ihm gespeichert werden muss
## (get_save_data / load_save_data). SaveGame sammelt nur ein und schreibt die
## Datei – so muss es nicht wissen, wie Inventar oder Garten innen aussehen,
## und neue Systeme (Kessel, NPCs …) kommen mit je einer Zeile dazu.
##
## Muss in der Autoload-Liste nach DayCycle, Inventory, Garden, Brewing, Grimoire, Wilds und WorldState stehen,
## damit die beim Laden schon bereit sind.

# user:// ist ein Ordner, den Godot pro Spiel anlegt. Unter Windows:
# %APPDATA%\Godot\app_userdata\<Projektname>\
const SAVE_PATH := "user://savegame.json"
# Geschrieben wird erst in eine Zwischendatei und erst danach umbenannt. So
# bleibt der alte Stand heil, falls das Spiel mitten im Schreiben abstürzt.
const TEMP_PATH := "user://savegame.json.tmp"
# Der vorletzte Stand. Ist der letzte kaputt, wird dieser geladen.
const BACKUP_PATH := "user://savegame.json.bak"
# Hochzählen, wenn sich das Format so ändert, dass alte Stände nicht mehr passen.
const VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


## Alles auf Anfang. Der alte Spielstand bleibt liegen, bis zum ersten Mal
## gespeichert wird.
func new_game() -> void:
	DayCycle.reset()
	Inventory.reset()
	Garden.reset()
	Brewing.reset()
	Grimoire.reset()
	Wilds.reset()
	WorldState.reset()
	# Nach DayCycle, damit die ersten Zettel zu Nacht 1 gehören.
	Requests.reset()


func save_game() -> void:
	var data := {
		"version": VERSION,
		"day_cycle": DayCycle.get_save_data(),
		"inventory": Inventory.get_save_data(),
		"garden": Garden.get_save_data(),
		"brewing": Brewing.get_save_data(),
		"grimoire": Grimoire.get_save_data(),
		"wilds": Wilds.get_save_data(),
		"world": WorldState.get_save_data(),
		"requests": Requests.get_save_data(),
	}
	# JSON statt Binärformat: Man kann die Datei beim Testen einfach lesen.
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Spielstand konnte nicht gespeichert werden: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(text)
	file.close()
	# Erst prüfen, dann tauschen: Ist die Zwischendatei unvollständig (Platte
	# voll o. Ä.), bleibt der alte Spielstand unangetastet.
	if FileAccess.get_file_as_string(TEMP_PATH) != text:
		push_error("Spielstand konnte nicht vollständig geschrieben werden")
		DirAccess.remove_absolute(TEMP_PATH)
		return
	if FileAccess.file_exists(SAVE_PATH):
		_replace(SAVE_PATH, BACKUP_PATH)
	_replace(TEMP_PATH, SAVE_PATH)
	print("Spielstand gespeichert (Nacht %d)" % DayCycle.day)


## Gibt false zurück, wenn es keinen brauchbaren Spielstand gibt. Ist der
## letzte Stand beschädigt, wird der vorletzte geladen.
func load_game() -> bool:
	for path in [SAVE_PATH, BACKUP_PATH]:
		var data := _read(path)
		if data.is_empty():
			continue
		if path == BACKUP_PATH:
			push_warning("Letzter Spielstand unbrauchbar, lade den vorletzten")
		_apply(data)
		print("Spielstand geladen (Nacht %d)" % DayCycle.day)
		return true
	return false


func delete_save() -> void:
	for path in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Spielstand gelöscht. Beim nächsten Start beginnt ein neues Spiel.")


## Liest und prüft eine Spielstand-Datei. Leer, wenn sie fehlt, beschädigt ist
## oder ein altes Format hat. Geprüft wird alles, bevor irgendein System etwas
## übernimmt: So landet nie ein halb geladener Stand im Spiel.
func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	# Ein JSON-Objekt statt JSON.parse_string: Das meldet einen Fehler als
	# Rückgabewert, statt ihn als Engine-Fehler ins Protokoll zu schreiben.
	var json := JSON.new()
	var parsed := json.parse(FileAccess.get_file_as_string(path))
	var data: Variant = json.data if parsed == OK else null
	if not data is Dictionary:
		push_warning("Spielstand %s ist beschädigt" % path)
		return {}
	# JSON kennt nur Kommazahlen, deshalb int().
	if int(data.get("version", 0)) != VERSION:
		push_warning("Spielstand %s hat ein altes Format" % path)
		return {}
	for part in ["day_cycle", "inventory", "garden"]:
		if not data.get(part) is Dictionary and not data.get(part) is Array:
			push_warning("Spielstand %s: Teil %s fehlt" % [path, part])
			return {}
	return data


func _apply(data: Dictionary) -> void:
	DayCycle.load_save_data(data["day_cycle"])
	Inventory.load_save_data(data["inventory"])
	Garden.load_save_data(data["garden"])
	# Ältere Spielstände haben noch keinen Brau-Teil.
	Brewing.load_save_data(data.get("brewing", {}))
	Grimoire.load_save_data(data.get("grimoire", {}))
	Wilds.load_save_data(data.get("wilds", {}))
	# Ältere Spielstände haben noch keine Welt-Merker: dann keine Flags.
	WorldState.load_save_data(data.get("world", {}))
	# Ältere Spielstände haben noch keine Gesuche: dann hängen neue Zettel.
	Requests.load_save_data(data.get("requests", {}))


## Benennt from in to um und ersetzt dabei eine vorhandene Datei.
func _replace(from: String, to: String) -> void:
	if FileAccess.file_exists(to):
		DirAccess.remove_absolute(to)
	var error := DirAccess.rename_absolute(from, to)
	if error != OK:
		push_error("Spielstand: %s -> %s fehlgeschlagen (%s)" % [from, to, error_string(error)])


# Nur zum Testen.
func _unhandled_input(event: InputEvent) -> void:
	# Debug-Taste: nur im Editor und in Debug-Exporten.
	if OS.is_debug_build() and event.is_action_pressed("debug_delete_save"):
		delete_save()
