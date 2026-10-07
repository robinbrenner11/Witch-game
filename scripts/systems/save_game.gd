extends Node

## Speichert und lädt den Spielstand. Gespeichert wird beim Schlafen und über
## das Pausemenü; geladen wird über "Fortsetzen" im Titelmenü.
##
## Jedes System liefert selbst, was von ihm gespeichert werden muss
## (get_save_data / load_save_data). SaveGame sammelt nur ein und schreibt die
## Datei – so muss es nicht wissen, wie Inventar oder Garten innen aussehen,
## und neue Systeme (Kessel, NPCs …) kommen mit je einer Zeile dazu.
##
## Muss in der Autoload-Liste nach DayCycle, Inventory, Garden und Brewing stehen,
## damit die beim Laden schon bereit sind.

# user:// ist ein Ordner, den Godot pro Spiel anlegt. Unter Windows:
# %APPDATA%\Godot\app_userdata\<Projektname>\
const SAVE_PATH := "user://savegame.json"
# Hochzählen, wenn sich das Format so ändert, dass alte Stände nicht mehr passen.
const VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Alles auf Anfang. Der alte Spielstand bleibt liegen, bis zum ersten Mal
## gespeichert wird.
func new_game() -> void:
	DayCycle.reset()
	Inventory.reset()
	Garden.reset()
	Brewing.reset()


func save_game() -> void:
	var data := {
		"version": VERSION,
		"day_cycle": DayCycle.get_save_data(),
		"inventory": Inventory.get_save_data(),
		"garden": Garden.get_save_data(),
		"brewing": Brewing.get_save_data(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Spielstand konnte nicht gespeichert werden: %s" % error_string(FileAccess.get_open_error()))
		return
	# JSON statt Binärformat: Man kann die Datei beim Testen einfach lesen.
	file.store_string(JSON.stringify(data, "\t"))
	print("Spielstand gespeichert (Nacht %d)" % DayCycle.day)


## Gibt false zurück, wenn es keinen brauchbaren Spielstand gibt.
func load_game() -> bool:
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		push_warning("Spielstand ist beschädigt")
		return false
	# JSON kennt nur Kommazahlen, deshalb int().
	if int(data.get("version", 0)) != VERSION:
		push_warning("Spielstand hat ein altes Format")
		return false
	DayCycle.load_save_data(data["day_cycle"])
	Inventory.load_save_data(data["inventory"])
	Garden.load_save_data(data["garden"])
	# Ältere Spielstände haben noch keinen Brau-Teil.
	if data.has("brewing"):
		Brewing.load_save_data(data["brewing"])
	print("Spielstand geladen (Nacht %d)" % DayCycle.day)
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	print("Spielstand gelöscht. Beim nächsten Start beginnt ein neues Spiel.")


# Nur zum Testen.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_delete_save"):
		delete_save()
