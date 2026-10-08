extends Node

## Was die Hexe bei sich trägt, aufgeteilt in Plätze. Läuft als Autoload,
## damit Beete, später Kessel, Händler und die Hotbar darauf zugreifen können,
## ohne einander zu kennen.
##
## Item-IDs sind einfache Strings: der Dateiname in data/items/ (z. B.
## "seed_mandrake"). Alles Weitere über ein Item steht in ItemData.

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

# Jeder Platz hat ein Item ("" = leer) und eine Anzahl. Ein Item kann auf
# mehreren Plätzen liegen, wenn ein Stapel voll ist (max_stack in ItemData,
# wie in Stardew Valley meist 999). Ein Platz wird frei, sobald er leer ist –
# die anderen Items bleiben, wo sie sind.
var _slot_items: Array[String] = []
var _slot_counts: Array[int] = []

# Welcher Hotbar-Platz gewählt ist, also was die Hexe "in der Hand" hat.
# Liegt hier statt in der Hotbar, weil Spiellogik (Beet, später Kessel) es
# braucht – die Hotbar zeigt es nur an. wrapi lässt das Mausrad rundum laufen.
var selected_slot: int = 0:
	set(value):
		selected_slot = wrapi(value, 0, HOTBAR_SIZE)
		selection_changed.emit()


func _ready() -> void:
	_slot_items.resize(SIZE)
	_slot_counts.resize(SIZE)
	reset()


## Neues Spiel: leere Tasche mit den Startsamen.
func reset() -> void:
	_slot_items.fill("")
	_slot_counts.fill(0)
	for item_id in START_ITEMS:
		add(item_id, START_ITEMS[item_id])
	selected_slot = 0


func _unhandled_input(event: InputEvent) -> void:
	# Debug-Taste: nur im Editor und in Debug-Exporten.
	if OS.is_debug_build() and event.is_action_pressed("debug_all_seeds"):
		for item_id in DEBUG_SEEDS:
			add(item_id, 3)
		print("Debug: je 3 Samen aller Sorten")


## Füllt erst angefangene Stapel desselben Items auf, dann freie Plätze.
## Passt nicht alles hinein, gibt es false zurück und ändert nichts.
func add(item_id: String, amount: int = 1) -> bool:
	if not has_room_for(item_id, amount):
		return false
	var left := amount
	var stack_size := max_stack(item_id)
	# Erst vorhandene Stapel, dann leere Plätze.
	for pass_item in [item_id, ""]:
		for slot in SIZE:
			if left == 0:
				break
			if _slot_items[slot] != pass_item:
				continue
			var put := mini(left, stack_size - _slot_counts[slot])
			if put <= 0:
				continue
			_slot_items[slot] = item_id
			_slot_counts[slot] += put
			left -= put
	changed.emit()
	item_added.emit(item_id, amount)
	return true


func has_room_for(item_id: String, amount: int = 1) -> bool:
	var room := 0
	var stack_size := max_stack(item_id)
	for slot in SIZE:
		if _slot_items[slot] == item_id:
			room += stack_size - _slot_counts[slot]
		elif _slot_items[slot] == "":
			room += stack_size
	return room >= amount


## Nimmt zuerst aus dem Platz in der Hand (was man benutzt, kommt von dort),
## dann von hinten. Gibt false zurück (und ändert nichts), wenn nicht genug da ist.
func remove(item_id: String, amount: int = 1) -> bool:
	if count(item_id) < amount:
		return false
	var order: Array[int] = [selected_slot]
	for slot in range(SIZE - 1, -1, -1):
		if slot != selected_slot:
			order.append(slot)
	var left := amount
	for slot in order:
		if left == 0:
			break
		if _slot_items[slot] == item_id:
			var taken := mini(left, _slot_counts[slot])
			_take(slot, taken)
			left -= taken
	changed.emit()
	return true


## Nimmt aus genau diesem Platz (z. B. beim Ziehen in den Kessel).
func remove_from_slot(slot: int, amount: int = 1) -> bool:
	if _slot_counts[slot] < amount:
		return false
	_take(slot, amount)
	changed.emit()
	return true


func get_save_data() -> Dictionary:
	return {"slots": _slot_items, "slot_counts": _slot_counts, "selected_slot": selected_slot}


func load_save_data(data: Dictionary) -> void:
	_slot_items.fill("")
	_slot_counts.fill(0)
	var saved_items: Array = data["slots"]
	for slot in mini(saved_items.size(), SIZE):
		_slot_items[slot] = saved_items[slot]
		if data.has("slot_counts"):
			_slot_counts[slot] = int(data["slot_counts"][slot])
		elif _slot_items[slot] != "":
			# Älterer Spielstand: Anzahl stand pro Item statt pro Platz.
			_slot_counts[slot] = int(data["counts"][_slot_items[slot]])
	selected_slot = int(data.get("selected_slot", 0))
	changed.emit()


## Drag & Drop: Liegt auf dem Ziel dasselbe Item, werden die Stapel
## zusammengelegt (soweit Platz ist). Sonst tauschen die beiden Plätze.
func move(from_slot: int, to_slot: int) -> void:
	if from_slot == to_slot:
		return
	var item_id := _slot_items[from_slot]
	if item_id != "" and _slot_items[to_slot] == item_id:
		var put := mini(_slot_counts[from_slot], max_stack(item_id) - _slot_counts[to_slot])
		_slot_counts[to_slot] += put
		_take(from_slot, put)
	else:
		_slot_items[from_slot] = _slot_items[to_slot]
		_slot_items[to_slot] = item_id
		var moved_count := _slot_counts[from_slot]
		_slot_counts[from_slot] = _slot_counts[to_slot]
		_slot_counts[to_slot] = moved_count
	changed.emit()


## Legt die Hälfte des Stapels (abgerundet) auf den ersten freien Platz.
## Gibt false zurück, wenn es nichts zu teilen gibt oder kein Platz frei ist.
func split_stack(slot: int) -> bool:
	var half := _slot_counts[slot] / 2
	var free_slot := _slot_items.find("")
	if half == 0 or free_slot == -1:
		return false
	_slot_items[free_slot] = _slot_items[slot]
	_slot_counts[free_slot] = half
	_slot_counts[slot] -= half
	changed.emit()
	return true


## Gesamtzahl über alle Plätze.
func count(item_id: String) -> int:
	var total := 0
	for slot in SIZE:
		if _slot_items[slot] == item_id:
			total += _slot_counts[slot]
	return total


func count_in_slot(slot: int) -> int:
	return _slot_counts[slot]


func max_stack(item_id: String) -> int:
	var item := ItemData.from_id(item_id)
	return item.max_stack if item else ItemData.DEFAULT_MAX_STACK


## Leerer String, wenn auf dem Platz nichts liegt.
func item_in_slot(slot: int) -> String:
	return _slot_items[slot]


func selected_item_id() -> String:
	return item_in_slot(selected_slot)


## Icons und Namen kommen aus data/items/. Leere Plätze ("") ergeben null bzw. "".
func icon_for(item_id: String) -> Texture2D:
	var item := ItemData.from_id(item_id)
	return item.icon if item else null


func display_name_for(item_id: String) -> String:
	var item := ItemData.from_id(item_id)
	# display_name ist ein Schlüssel in data/translations/texts.csv.
	return tr(item.display_name) if item else ""


func _take(slot: int, amount: int) -> void:
	_slot_counts[slot] -= amount
	if _slot_counts[slot] == 0:
		_slot_items[slot] = ""
