extends Node

## Was in der Welt von selbst wächst und eingesammelt werden kann: Wildgras,
## Unkraut, später Pilze, Beeren, Federn. Läuft als Autoload, damit es auch
## nachwächst, wenn der Ort gerade nicht geladen ist, und damit der
## Spielstand es speichern kann.
##
## Die Orte zeigen es nur an: Ein WildGrowth-Node im Ort legt fest, was dort
## wächst und wo, und meldet sich hier unter einem Namen an ("Garten/Wildgras").
## Hier steht pro Name, welche Stücke gerade wo liegen und wie viele beim
## nächsten Besuch neu dazukommen.

# Name -> {
#   "items": {id: {"scene": Pfad, "x": int, "y": int}},
#   "next_id": int, "max": int, "pause": int,
#   "nights_since_clear": int, "pending": int,
# }
# Bewusst einfache Dictionaries: lassen sich direkt als JSON speichern.
var _places: Dictionary = {}


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)


func reset() -> void:
	_places.clear()


func is_known(place: String) -> bool:
	return _places.has(place)


## Meldet einen Ort an oder aktualisiert seine Regeln (die kommen aus dem
## WildGrowth-Node und können sich beim Entwickeln ändern).
func register(place: String, max_count: int, pause_nights: int) -> void:
	if not _places.has(place):
		_places[place] = {
			"items": {}, "next_id": 0, "pending": 0, "nights_since_clear": 0,
		}
	_places[place]["max"] = max_count
	_places[place]["pause"] = pause_nights


func items(place: String) -> Dictionary:
	return _places[place]["items"]


func add_item(place: String, scene_path: String, at: Vector2) -> String:
	var data: Dictionary = _places[place]
	var id := str(int(data["next_id"]))
	data["next_id"] = int(data["next_id"]) + 1
	data["items"][id] = {"scene": scene_path, "x": roundi(at.x), "y": roundi(at.y)}
	return id


## Eingesammelt oder weggeräumt. Danach macht das Nachwachsen eine Pause.
func remove_item(place: String, id: String) -> void:
	_places[place]["items"].erase(id)
	_places[place]["nights_since_clear"] = 0


## Wie viele Büschel beim Laden des Ortes neu wachsen sollen. Setzt den
## Zähler zurück, weil der Ort sie jetzt platziert.
func take_pending(place: String) -> int:
	var count: int = _places[place]["pending"]
	_places[place]["pending"] = 0
	return count


func get_save_data() -> Dictionary:
	return _places.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_places = data.duplicate(true)


## Jede Nacht ein Büschel mehr, bis zum Höchstwert. Nach dem Aufräumen erst
## eine Pause (so wuchert es nicht gleich wieder zu). pending zählt Büschel;
## wie viele Stücke eins hat und dass max nicht überschritten wird, regelt
## WildGrowth beim Platzieren.
func _on_day_passed(_day: int) -> void:
	for place: String in _places:
		var data: Dictionary = _places[place]
		data["nights_since_clear"] = int(data["nights_since_clear"]) + 1
		if int(data["nights_since_clear"]) > int(data["pause"]) and data["items"].size() < int(data["max"]):
			data["pending"] = int(data["pending"]) + 1
