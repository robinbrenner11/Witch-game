extends Node

## Was die Hexe bei sich trägt, aufgeteilt in Plätze. Läuft als Autoload,
## damit Beete, später Kessel, Händler und die Hotbar darauf zugreifen können,
## ohne einander zu kennen.
##
## Item-IDs sind einfache Strings nach dem Schema "seed_<pflanze>" und
## "crop_<pflanze>" (gleiche Namen wie die Grafiken in assets/items/).

signal changed
signal selection_changed
# Für Rückmeldungen wie "+1 Alraune". Kommt zusätzlich zu changed.
signal item_added(item_id: String, amount: int)

# Gesamtzahl der Plätze. Die ersten HOTBAR_SIZE davon liegen in der Hotbar
# (Tasten 1–8), der Rest kommt später in ein Inventar-Fenster.
const SIZE := 24
const HOTBAR_SIZE := 8

# Bewusst nur drei Arten zum Start – Nachtschatten, Mondkelch und Blutrose
# soll die Hexe später finden.
const START_ITEMS := {
	"seed_mandrake": 3,
	"seed_ghost_fern": 3,
	"seed_lantern_berry": 3,
}

# Nur zum Testen (Debug-Taste): alle Samensorten auf einmal.
const DEBUG_SEEDS := [
	"seed_mandrake", "seed_ghost_fern", "seed_lantern_berry",
	"seed_nightshade", "seed_moon_chalice", "seed_blood_rose",
]

# Welches Item auf welchem Platz liegt ("" = leer). Jedes Item belegt genau
# einen Platz; die Anzahl steht getrennt in _counts. Ein Platz wird frei,
# sobald sein Item aufgebraucht ist – die anderen Items bleiben, wo sie sind.
var _slots: Array[String] = []
var _counts: Dictionary[String, int] = {}

# Welcher Hotbar-Platz gewählt ist, also was die Hexe "in der Hand" hat.
# Liegt hier statt in der Hotbar, weil Spiellogik (Beet, später Kessel) es
# braucht – die Hotbar zeigt es nur an. wrapi lässt das Mausrad rundum laufen.
var selected_slot: int = 0:
	set(value):
		selected_slot = wrapi(value, 0, HOTBAR_SIZE)
		selection_changed.emit()


func _ready() -> void:
	_slots.resize(SIZE)
	_slots.fill("")
	for item_id in START_ITEMS:
		add(item_id, START_ITEMS[item_id])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_all_seeds"):
		for item_id in DEBUG_SEEDS:
			add(item_id, 3)
		print("Debug: je 3 Samen aller Sorten")


## Neue Items landen auf dem ersten freien Platz. Gibt false zurück (und
## ändert nichts), wenn das Item noch keinen Platz hat und alles voll ist.
func add(item_id: String, amount: int = 1) -> bool:
	if not _counts.has(item_id):
		var free_slot := _slots.find("")
		if free_slot == -1:
			return false
		_slots[free_slot] = item_id
	_counts[item_id] = count(item_id) + amount
	changed.emit()
	item_added.emit(item_id, amount)
	return true


func has_room_for(item_id: String) -> bool:
	return _counts.has(item_id) or _slots.has("")


## Gibt false zurück (und ändert nichts), wenn nicht genug da ist.
func remove(item_id: String, amount: int = 1) -> bool:
	if count(item_id) < amount:
		return false
	_counts[item_id] -= amount
	if _counts[item_id] == 0:
		_counts.erase(item_id)
		_slots[_slots.find(item_id)] = ""
	changed.emit()
	return true


func get_save_data() -> Dictionary:
	return {"slots": _slots, "counts": _counts, "selected_slot": selected_slot}


func load_save_data(data: Dictionary) -> void:
	_slots.fill("")
	var saved_slots: Array = data["slots"]
	for i in mini(saved_slots.size(), SIZE):
		_slots[i] = saved_slots[i]
	_counts.clear()
	for item_id in data["counts"]:
		_counts[item_id] = int(data["counts"][item_id])
	selected_slot = int(data.get("selected_slot", 0))
	changed.emit()


## Tauscht den Inhalt zweier Plätze (Drag & Drop). Ist das Ziel leer, wird
## das Item einfach verschoben.
func move(from_slot: int, to_slot: int) -> void:
	if from_slot == to_slot:
		return
	var moved := _slots[from_slot]
	_slots[from_slot] = _slots[to_slot]
	_slots[to_slot] = moved
	changed.emit()


func count(item_id: String) -> int:
	return _counts.get(item_id, 0)


## Leerer String, wenn auf dem Platz nichts liegt.
func item_in_slot(slot: int) -> String:
	return _slots[slot]


func selected_item_id() -> String:
	return item_in_slot(selected_slot)


## Icons und Namen kommen aus data/items/. Samen und Ernte haben dort (noch)
## keine eigene Datei und werden aus den Pflanzendaten abgeleitet.
func icon_for(item_id: String) -> Texture2D:
	var item := ItemData.from_id(item_id)
	if item:
		return item.icon
	if item_id.begins_with("seed_"):
		return PlantData.from_id(item_id.trim_prefix("seed_")).seed_icon
	if item_id.begins_with("crop_"):
		return PlantData.from_id(item_id.trim_prefix("crop_")).crop_icon
	return null


func display_name_for(item_id: String) -> String:
	var item := ItemData.from_id(item_id)
	if item:
		return item.display_name
	if item_id.begins_with("seed_"):
		return PlantData.from_id(item_id.trim_prefix("seed_")).display_name + "-Samen"
	if item_id.begins_with("crop_"):
		return PlantData.from_id(item_id.trim_prefix("crop_")).display_name
	return ""
