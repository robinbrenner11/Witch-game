extends Node

## Alles rund ums Brauen, was über eine Szene hinaus gilt: wie viele Zutaten
## der Kessel fasst (aufrüstbar) und welche Kombinationen die Hexe schon
## gebraut hat. Später kommt hier dazu, was gerade über Nacht im Kessel braut.

const START_CAPACITY := 3
# Ab so vielen Zutaten kann gebraut werden.
const MIN_INGREDIENTS := 2

var capacity: int = START_CAPACITY

# Schon gebraute Kombinationen: sortierte Zutaten (z. B.
# "crop_ghost_fern+crop_mandrake") -> Ergebnis. Bekanntes zeigt das
# Brau-Fenster mit Namen an, alles andere als "???".
var _known: Dictionary[String, String] = {}


## Leerer String, wenn die Hexe diese Kombination noch nie gebraut hat.
func known_result(ingredients: Array[String]) -> String:
	return _known.get(_key(ingredients), "")


func learn(ingredients: Array[String], result_item_id: String) -> void:
	_known[_key(ingredients)] = result_item_id


func get_save_data() -> Dictionary:
	return {"capacity": capacity, "known": _known}


func load_save_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", START_CAPACITY))
	_known.clear()
	var known: Dictionary = data.get("known", {})
	for key in known:
		_known[key] = String(known[key])


# Reihenfolge egal, also sortiert als Schlüssel.
static func _key(ingredients: Array[String]) -> String:
	var sorted := ingredients.duplicate()
	sorted.sort()
	return "+".join(PackedStringArray(sorted))
