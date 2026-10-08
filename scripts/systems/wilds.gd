extends Node

## Was in der Welt von selbst wächst und eingesammelt werden kann: Wildgras,
## Unkraut, Pilze, Beeren, Federn, Mondmoos. Läuft als Autoload, damit es auch
## nachwächst, wenn der Ort gerade nicht geladen ist, und damit der
## Spielstand es speichern kann.
##
## Die Orte zeigen es nur an: Ein WildGrowth-Node im Ort legt fest, was dort
## wächst, wo und nach welcher Regel, und meldet sich hier unter einem Namen
## an ("forest/weeds"). Hier steht pro Name, welche Stücke gerade wo liegen
## und wie viele beim nächsten Besuch neu dazukommen.

# Wie Neues entsteht (Regel pro Name, kommt aus WildGrowth):
# "steady"  Jede Nacht etwas Neues, nach dem Einsammeln erst "pause" Nächte Ruhe (Wildgras).
# "respawn" Jedes eingesammelte Stück kommt nach "respawn_nights" woanders wieder (Pilze).
# "chance"  Jede Nacht mit Wahrscheinlichkeit "chance" ein neues Stück (Federn, Sträucher).
# "none"    Es kommt nichts Neues dazu (Moos-Steine; die tragen nur selbst neu).
const MODES: Array[String] = ["steady", "respawn", "chance", "none"]

# Name -> {
#   "items": {id: {"scene": Pfad, "x": int, "y": int, "state": {}}},
#   "next_id": int, "pending": int, "nights_since_clear": int, "timers": [int],
#   "rules": {"mode", "max", "pause", "respawn_nights", "chance"},
# }
# "state" gehört dem Objekt selbst, z. B. wann ein Strauch wieder trägt.
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
func register(place: String, rules: Dictionary) -> void:
	if not _places.has(place):
		_places[place] = {
			"items": {}, "next_id": 0, "pending": 0, "nights_since_clear": 0, "timers": [],
		}
	_places[place]["rules"] = rules


func items(place: String) -> Dictionary:
	return _places[place]["items"]


func add_item(place: String, scene_path: String, at: Vector2) -> String:
	var data: Dictionary = _places[place]
	var id := str(int(data["next_id"]))
	data["next_id"] = int(data["next_id"]) + 1
	data["items"][id] = {"scene": scene_path, "x": roundi(at.x), "y": roundi(at.y), "state": {}}
	return id


## Eigener Zustand eines Stücks. Änderungen am zurückgegebenen Dictionary
## werden direkt gespeichert. Leer bei Stücken aus älteren Spielständen.
func item_state(place: String, id: String) -> Dictionary:
	var item: Dictionary = _places[place]["items"][id]
	if not item.has("state"):
		item["state"] = {}
	return item["state"]


## Eingesammelt oder weggeräumt, das Stück ist weg.
func remove_item(place: String, id: String) -> void:
	var data: Dictionary = _places[place]
	data["items"].erase(id)
	data["nights_since_clear"] = 0
	if data["rules"]["mode"] == "respawn":
		data["timers"].append(int(data["rules"]["respawn_nights"]))


## Wie viele Büschel bzw. Stücke beim Laden des Ortes neu wachsen sollen.
## Setzt den Zähler zurück, weil der Ort sie jetzt platziert.
func take_pending(place: String) -> int:
	var count: int = _places[place]["pending"]
	_places[place]["pending"] = 0
	return count


func get_save_data() -> Dictionary:
	return _places.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_places = data.duplicate(true)


## Wie viele beim nächsten Besuch neu kommen, regelt die Regel des Namens.
## pending zählt Büschel; wie viele Stücke eins hat und dass max nicht
## überschritten wird, regelt WildGrowth beim Platzieren.
func _on_day_passed(_day: int) -> void:
	for place: String in _places:
		var data: Dictionary = _places[place]
		var rules: Dictionary = data.get("rules", {})
		var below_max: bool = data["items"].size() + int(data["pending"]) < int(rules.get("max", 0))
		data["nights_since_clear"] = int(data["nights_since_clear"]) + 1
		_tick_items(data)
		match rules.get("mode", "none"):
			"steady":
				if int(data["nights_since_clear"]) > int(rules["pause"]) and data["items"].size() < int(rules["max"]):
					data["pending"] = int(data["pending"]) + 1
			"respawn":
				var timers: Array = data["timers"]
				for i in timers.size():
					timers[i] = int(timers[i]) - 1
				# Nach dem Laden aus JSON sind es Kommazahlen, daher int().
				var due := timers.filter(func(t: Variant) -> bool: return int(t) <= 0).size()
				data["timers"] = timers.filter(func(t: Variant) -> bool: return int(t) > 0)
				data["pending"] = int(data["pending"]) + due
			"chance":
				if below_max and randf() < float(rules["chance"]):
					data["pending"] = int(data["pending"]) + 1


## Stücke, die nach dem Pflücken stehen bleiben (Beerenstrauch), zählen
## hier die Nächte herunter, bis sie wieder tragen.
func _tick_items(data: Dictionary) -> void:
	for id: String in data["items"]:
		var state: Dictionary = data["items"][id].get("state", {})
		if int(state.get("regrow_in", 0)) > 0:
			state["regrow_in"] = int(state["regrow_in"]) - 1
