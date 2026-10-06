extends Node

## Was die Hexe bei sich trägt: Item-ID -> Anzahl. Läuft als Autoload, damit
## Beete, später Kessel, Händler und die Hotbar darauf zugreifen können,
## ohne einander zu kennen.
##
## Item-IDs sind einfache Strings nach dem Schema "seed_<pflanze>" und
## "crop_<pflanze>" (gleiche Namen wie die Grafiken in assets/items/).

signal changed
signal selection_changed

# Die ersten Plätze des Inventars liegen in der Hotbar (Tasten 1–8).
const HOTBAR_SIZE := 8

# Bewusst nur drei Arten zum Start – die anderen soll die Hexe später finden.
const START_ITEMS := {
	"seed_mandrake": 3,
	"seed_nightshade": 3,
	"seed_moon_chalice": 3,
}

# Dictionaries behalten in GDScript die Einfüge-Reihenfolge. Die Reihenfolge,
# in der Items dazukommen, ist also auch die Reihenfolge in der Hotbar.
var _items: Dictionary[String, int] = {}

# Welcher Hotbar-Platz gewählt ist, also was die Hexe "in der Hand" hat.
# Liegt hier statt in der Hotbar, weil Spiellogik (Beet, später Kessel) es
# braucht – die Hotbar zeigt es nur an. wrapi lässt das Mausrad rundum laufen.
var selected_slot: int = 0:
	set(value):
		selected_slot = wrapi(value, 0, HOTBAR_SIZE)
		selection_changed.emit()


func _ready() -> void:
	for item_id in START_ITEMS:
		add(item_id, START_ITEMS[item_id])


func add(item_id: String, amount: int = 1) -> void:
	_items[item_id] = count(item_id) + amount
	changed.emit()


## Gibt false zurück (und ändert nichts), wenn nicht genug da ist.
func remove(item_id: String, amount: int = 1) -> bool:
	if count(item_id) < amount:
		return false
	_items[item_id] -= amount
	# Leere Einträge bleiben stehen, damit Items in der Hotbar nicht
	# herumspringen, wenn sie aufgebraucht und später wieder da sind.
	changed.emit()
	return true


func count(item_id: String) -> int:
	return _items.get(item_id, 0)


func item_ids() -> Array[String]:
	# keys() liefert ein untypisiertes Array; assign() wandelt es um.
	var ids: Array[String] = []
	ids.assign(_items.keys())
	return ids


## Leerer String, wenn auf dem Platz nichts liegt.
func item_in_slot(slot: int) -> String:
	var ids := item_ids()
	return ids[slot] if slot < ids.size() else ""


func selected_item_id() -> String:
	return item_in_slot(selected_slot)


## Vorläufig kommen Icons aus den Pflanzendaten, weil es bisher nur Samen und
## Ernte gibt. Sobald andere Items (Tränke …) dazukommen, bekommt jedes Item
## eine eigene Datendatei in data/items/ – dann ändert sich nur diese Funktion.
func icon_for(item_id: String) -> Texture2D:
	if item_id.begins_with("seed_"):
		return PlantData.from_id(item_id.trim_prefix("seed_")).seed_icon
	if item_id.begins_with("crop_"):
		return PlantData.from_id(item_id.trim_prefix("crop_")).crop_icon
	return null


## Anzeigename für die UI. Wie icon_for() vorläufig aus den Pflanzendaten.
func display_name_for(item_id: String) -> String:
	if item_id.begins_with("seed_"):
		return PlantData.from_id(item_id.trim_prefix("seed_")).display_name + "-Samen"
	if item_id.begins_with("crop_"):
		return PlantData.from_id(item_id.trim_prefix("crop_")).display_name
	return ""
