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
# Welche Teile ein Spielstand haben muss und welchen Typ jeder Teil hat.
# Fehlt ein Pflichtteil oder hat irgendein Teil den falschen Typ, gilt der
# ganze Stand als beschädigt (dann wird das Backup versucht), bevor irgendein
# System etwas übernimmt. Der Garten kennt aus alten Ständen noch eine Liste.
const REQUIRED_PARTS := ["day_cycle", "inventory", "garden"]
const PART_TYPES := {
	"day_cycle": [TYPE_DICTIONARY], "inventory": [TYPE_DICTIONARY],
	"garden": [TYPE_DICTIONARY, TYPE_ARRAY], "brewing": [TYPE_DICTIONARY],
	"grimoire": [TYPE_DICTIONARY], "wilds": [TYPE_DICTIONARY],
	"world": [TYPE_DICTIONARY], "requests": [TYPE_DICTIONARY],
	"player": [TYPE_DICTIONARY],
}

# Die Pfade als Variablen, damit Tests eigene Dateien nutzen können, ohne den
# echten Spielstand anzufassen.
var save_path := SAVE_PATH
var temp_path := TEMP_PATH
var backup_path := BACKUP_PATH
# Zustand der Hexe (Leben, Hexenkraft, Trankwirkungen) aus dem geladenen
# Stand. Die Hexe ist kein Autoload: Sie holt ihn sich beim Start ab
# (take_player_data), und solange es keine Hexe gibt, wird er so weitergespeichert.
var _player_data: Dictionary = {}


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)


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
	NightLog.reset()
	_player_data = {}


## Alles, was gespeichert wird, als ein Dictionary (so landet es als JSON in
## der Datei). Eigene Funktion, damit Tests den Spielstand prüfen können,
## ohne die echte Datei zu überschreiben.
func collect() -> Dictionary:
	return {
		"version": VERSION,
		"day_cycle": DayCycle.get_save_data(),
		"inventory": Inventory.get_save_data(),
		"garden": Garden.get_save_data(),
		"brewing": Brewing.get_save_data(),
		"grimoire": Grimoire.get_save_data(),
		"wilds": Wilds.get_save_data(),
		"world": WorldState.get_save_data(),
		"requests": Requests.get_save_data(),
		"player": player_data(),
	}


## Zustand der Hexe, wenn es sie gerade gibt, sonst der zuletzt geladene.
func player_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player and player.has_method("get_save_data"):
		return player.get_save_data()
	return _player_data


## Gibt den geladenen Zustand der Hexe einmal heraus (leer = Neustart-Werte).
func take_player_data() -> Dictionary:
	var data := _player_data
	_player_data = {}
	return data


## Gibt true zurück, wenn der Stand sicher auf der Platte liegt. Bei false
## ist der bisherige Spielstand (oder sein Backup) unverändert erhalten, und
## der Aufrufer muss das der Spielerin sagen (Pausemenü, Bett).
func save_game() -> bool:
	var data := collect()
	# JSON statt Binärformat: Man kann die Datei beim Testen einfach lesen.
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Spielstand konnte nicht gespeichert werden: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.close()
	# Erst prüfen, dann tauschen: Ist die Zwischendatei unvollständig (Platte
	# voll o. Ä.), bleibt der alte Spielstand unangetastet.
	if FileAccess.get_file_as_string(temp_path) != text:
		push_error("Spielstand konnte nicht vollständig geschrieben werden")
		DirAccess.remove_absolute(temp_path)
		return false
	if not _swap_in():
		return false
	print("Spielstand gespeichert (Nacht %d)" % DayCycle.day)
	return true


## Zwischendatei an die Stelle des Spielstands, alter Stand wird Backup.
## Scheitert der zweite Schritt, kommt das Backup zurück an seinen Platz,
## damit nie beide Dateien fehlen.
func _swap_in() -> bool:
	if FileAccess.file_exists(save_path):
		if not _replace(save_path, backup_path):
			DirAccess.remove_absolute(temp_path)
			return false
	if not _replace(temp_path, save_path):
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(backup_path, save_path)
		return false
	return true


## Gibt false zurück, wenn es keinen brauchbaren Spielstand gibt. Ist der
## letzte Stand beschädigt, wird der vorletzte geladen.
func load_game() -> bool:
	for path in [save_path, backup_path]:
		var data := _read(path)
		if data.is_empty():
			continue
		if path == backup_path:
			push_warning("Letzter Spielstand unbrauchbar, lade den vorletzten")
		_apply(data)
		print("Spielstand geladen (Nacht %d)" % DayCycle.day)
		return true
	return false


func delete_save() -> void:
	for path in [save_path, backup_path, temp_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Spielstand gelöscht. Beim nächsten Start beginnt ein neues Spiel.")


## Liest und prüft eine Spielstand-Datei. Leer, wenn sie fehlt, beschädigt ist
## oder ein altes Format hat. Geprüft werden Version, Pflichtteile und der Typ
## jedes Teils (is_valid), bevor irgendein System etwas übernimmt. Einzelwerte
## in den Teilen prüfen die Systeme selbst beim Laden (data.get mit Standard).
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
	if not is_valid(data):
		push_warning("Spielstand %s: Teile fehlen oder haben den falschen Typ" % path)
		return {}
	return data


## Alle Pflichtteile da, und jeder vorhandene Teil hat den erwarteten Typ.
static func is_valid(data: Dictionary) -> bool:
	for part in REQUIRED_PARTS:
		if not data.has(part):
			return false
	for part: String in PART_TYPES:
		if data.has(part) and not typeof(data[part]) in PART_TYPES[part]:
			return false
	return true


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
	NightLog.reset()
	_player_data = data.get("player", {})


## Benennt from in to um und ersetzt dabei eine vorhandene Datei.
func _replace(from: String, to: String) -> bool:
	if FileAccess.file_exists(to):
		DirAccess.remove_absolute(to)
	var error := DirAccess.rename_absolute(from, to)
	if error != OK:
		push_error("Spielstand: %s -> %s fehlgeschlagen (%s)" % [from, to, error_string(error)])
		return false
	return true


# Nur zum Testen.
func _unhandled_input(event: InputEvent) -> void:
	# Debug-Taste: nur im Editor und in Debug-Exporten.
	if OS.is_debug_build() and event.is_action_pressed("debug_delete_save"):
		delete_save()
