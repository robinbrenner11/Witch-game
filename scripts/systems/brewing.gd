extends Node

## Alles rund ums Brauen, was über eine Szene hinaus gilt: wie viele Zutaten
## der Kessel fasst (aufrüstbar), welche Kombinationen die Hexe schon gebraut
## hat und was gerade über Nacht im Kessel braut. Liegt in einem Autoload,
## damit der Trank auch fertig wird, wenn die Kessel-Szene nicht geladen ist.
##
## Ablauf: start() legt Zutaten in den Kessel. Bei Tageswechsel wird daraus
## ein Trank (1 pro Vorgang) – erst dann erfährt die Hexe, was es ist. Er
## wartet im Kessel, bis sie ihn mit take_finished() abholt.

# Kommt, wenn sich am Kessel etwas ändert (Brauen begonnen, fertig, abgeholt).
signal changed

const START_CAPACITY := 3
# Ab so vielen Zutaten kann gebraut werden.
const MIN_INGREDIENTS := 2

var capacity: int = START_CAPACITY

# Schon gebraute Kombinationen: sortierte Zutaten (z. B.
# "crop_ghost_fern+crop_mandrake") -> Ergebnis. Bekanntes zeigt das
# Brau-Fenster mit Namen an, alles andere als "???".
var _known: Dictionary[String, String] = {}
# Zutaten, die gerade über Nacht brauen (leer = Kessel frei).
var _brewing: Array[String] = []
# Fertiger Trank, der auf Abholung wartet ("" = keiner).
var _finished: String = ""


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)


func is_brewing() -> bool:
	return not _brewing.is_empty()


func brewing_ingredients() -> Array[String]:
	return _brewing.duplicate()


func finished_potion() -> String:
	return _finished


## Nur ein Vorgang gleichzeitig, und ein fertiger Trank muss erst raus.
func can_start() -> bool:
	return not is_brewing() and _finished == ""


func start(ingredients: Array[String]) -> void:
	_brewing = ingredients.duplicate()
	changed.emit()


## Gibt false zurück, wenn nichts fertig ist oder das Inventar voll ist.
func take_finished() -> bool:
	if _finished == "" or not Inventory.add(_finished):
		return false
	_finished = ""
	Journal.complete_goal("brew")
	changed.emit()
	return true


## Leerer String, wenn die Hexe diese Kombination weder gebraut noch auf einer
## losen Buchseite gelesen hat.
func known_result(ingredients: Array[String]) -> String:
	var key := _key(ingredients)
	if _known.has(key):
		return _known[key]
	for recipe in RecipeData.all():
		if recipe.matches(ingredients) and Journal.is_page_found(recipe.result_item_id):
			return recipe.result_item_id
	return ""


## Hat die Hexe diesen Trank schon einmal gebraut?
func has_brewed(result_item_id: String) -> bool:
	return _known.values().has(result_item_id)


func learn(ingredients: Array[String], result_item_id: String) -> void:
	_known[_key(ingredients)] = result_item_id


## Neues Spiel: leerer Kessel, nichts bekannt, Startkapazität.
func reset() -> void:
	load_save_data({})


func get_save_data() -> Dictionary:
	return {"capacity": capacity, "known": _known, "brewing": _brewing, "finished": _finished}


func load_save_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", START_CAPACITY))
	_known.clear()
	var known: Dictionary = data.get("known", {})
	for key in known:
		_known[key] = String(known[key])
	_brewing.clear()
	for item_id in data.get("brewing", []):
		_brewing.append(String(item_id))
	_finished = String(data.get("finished", ""))
	changed.emit()


func _on_day_passed(_day: int) -> void:
	if not is_brewing():
		return
	_finished = RecipeData.result_for(_brewing)
	learn(_brewing, _finished)
	_brewing.clear()
	changed.emit()


# Reihenfolge egal, also sortiert als Schlüssel.
static func _key(ingredients: Array[String]) -> String:
	var sorted := ingredients.duplicate()
	sorted.sort()
	return "+".join(PackedStringArray(sorted))
