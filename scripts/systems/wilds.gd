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
# Mehr neue Büschel stauen sich pro Ort nicht an (auch nicht aus einem
# kaputten Spielstand).
const MAX_PENDING := 20

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


## Baut jeden Ort aus dem Spielstand neu auf, statt ihn ungeprüft zu
## übernehmen: Was nicht die erwartete Form hat, fällt weg oder bekommt den
## Standardwert. Die Orte (WildGrowth, Forage) verlassen sich danach darauf.
func load_save_data(data: Dictionary) -> void:
	_places.clear()
	for place: Variant in data:
		if not place is String or not data[place] is Dictionary:
			continue
		var saved: Dictionary = data[place]
		var items := {}
		var highest_id := -1
		var saved_items := SaveRead.as_dict(saved.get("items"))
		for id: Variant in saved_items:
			var item := SaveRead.as_dict(saved_items[id])
			var scene := SaveRead.as_string(item.get("scene"))
			if not id is String or scene == "":
				continue
			items[id] = {
				"scene": scene,
				"x": SaveRead.as_int(item.get("x")), "y": SaveRead.as_int(item.get("y")),
				"state": _clean_state(item.get("state")),
			}
			if (id as String).is_valid_int():
				highest_id = maxi(highest_id, (id as String).to_int())
		var timers: Array = []
		for timer: Variant in SaveRead.as_array(saved.get("timers")):
			if (timer is float or timer is int) and SaveRead.as_int(timer) > 0:
				timers.append(SaveRead.as_int(timer))
		_places[place] = {
			"items": items,
			# Nie eine ID vergeben, die es schon gibt.
			"next_id": maxi(SaveRead.as_int(saved.get("next_id")), highest_id + 1),
			"pending": clampi(SaveRead.as_int(saved.get("pending")), 0, MAX_PENDING),
			"nights_since_clear": maxi(SaveRead.as_int(saved.get("nights_since_clear")), 0),
			"timers": timers,
			"rules": _clean_rules(saved.get("rules")),
		}


## Regeln, wie sie WildGrowth anmeldet. Bis der Ort wieder besucht wird (dann
## kommen frische Regeln), rechnet _on_day_passed mit diesen.
func _clean_rules(value: Variant) -> Dictionary:
	var rules := SaveRead.as_dict(value)
	var mode := SaveRead.as_string(rules.get("mode"), "none")
	return {
		"mode": mode if mode in MODES else "none",
		"max": maxi(SaveRead.as_int(rules.get("max")), 0),
		"pause": maxi(SaveRead.as_int(rules.get("pause"), 1), 0),
		"respawn_nights": maxi(SaveRead.as_int(rules.get("respawn_nights"), 1), 1),
		"chance": clampf(SaveRead.as_float(rules.get("chance")), 0.0, 1.0),
	}


## Eigener Zustand eines Stücks: nur einfache Werte (Zahl, Text, ja/nein).
func _clean_state(value: Variant) -> Dictionary:
	var state := {}
	var saved := SaveRead.as_dict(value)
	for key: Variant in saved:
		var entry: Variant = saved[key]
		if not key is String:
			continue
		if entry is float or entry is int:
			state[key] = SaveRead.as_int(entry)
		elif entry is String or entry is bool:
			state[key] = entry
	return state


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
