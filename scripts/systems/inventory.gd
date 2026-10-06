extends Node

## Was die Hexe bei sich trägt: Item-ID -> Anzahl. Läuft als Autoload, damit
## Beete, später Kessel, Händler und die Hotbar darauf zugreifen können,
## ohne einander zu kennen.
##
## Item-IDs sind einfache Strings nach dem Schema "seed_<pflanze>" und
## "crop_<pflanze>" (gleiche Namen wie die Grafiken in assets/items/).

signal changed

# Bewusst nur drei Arten zum Start – die anderen soll die Hexe später finden.
const START_ITEMS := {
	"seed_mandrake": 3,
	"seed_nightshade": 3,
	"seed_moon_chalice": 3,
}

# Dictionaries behalten in GDScript die Einfüge-Reihenfolge. Die Reihenfolge,
# in der Items dazukommen, ist also auch die Reihenfolge in der Hotbar.
var _items: Dictionary[String, int] = {}


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
