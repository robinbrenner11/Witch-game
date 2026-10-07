extends Node

## Was in welchem Beet wächst. Läuft als Autoload, damit der Garten auch dann
## weiterwächst, wenn die Garten-Szene gerade nicht geladen ist (Hexe im
## Unterschlupf oder Wald), und damit der Spielstand ihn speichern kann.
##
## Die Beete (FarmTile) und Pflanzen (Plant) in der Szene sind nur die
## Anzeige: Sie lesen ihren Zustand von hier und melden Änderungen hierher.
##
## Ein Beet wird über seine Tile-Koordinate angesprochen. Beete gibt es nur
## im Garten, deshalb reicht die Koordinate ohne Szenennamen.

# Kommt bei jeder Änderung an einem Beet (gepflanzt, gewachsen, geerntet).
signal plant_changed(cell: Vector2i)

const TILE_SIZE := 32

# Zelle -> {"plant_id": String, "stage": int}. Bewusst ein einfaches
# Dictionary statt eigener Klasse: lässt sich direkt speichern.
var _plants: Dictionary[Vector2i, Dictionary] = {}


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)


## Rechnet eine Weltposition in die Zelle um, in der sie liegt.
static func cell_at(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / TILE_SIZE).floor())


func has_plant(cell: Vector2i) -> bool:
	return _plants.has(cell)


## null, wenn dort nichts wächst.
func plant_data_at(cell: Vector2i) -> PlantData:
	if not has_plant(cell):
		return null
	return PlantData.from_id(_plants[cell]["plant_id"])


func stage_at(cell: Vector2i) -> int:
	return _plants[cell]["stage"] if has_plant(cell) else 0


func is_ripe(cell: Vector2i) -> bool:
	return has_plant(cell) and stage_at(cell) >= plant_data_at(cell).stage_count - 1


func plant_seed(cell: Vector2i, plant_id: String) -> void:
	_plants[cell] = {"plant_id": plant_id, "stage": 0}
	plant_changed.emit(cell)


func remove_plant(cell: Vector2i) -> void:
	_plants.erase(cell)
	plant_changed.emit(cell)


## Eine Stufe weiter, egal ob die Nacht es erlaubt. So wirkt Magie
## (Wachstumstrank, später Hexenschlamm); das natürliche Wachstum läuft
## über can_grow_tonight().
func grow(cell: Vector2i) -> void:
	if not has_plant(cell) or is_ripe(cell):
		return
	_plants[cell]["stage"] += 1
	plant_changed.emit(cell)


## Hier docken später Bedingungen an: Mondphase (Mondkelch), Nachbarn
## (Nachtschatten), Blutrose ab Stufe 3 usw.
func can_grow_tonight(cell: Vector2i) -> bool:
	return not is_ripe(cell)


## JSON kennt keine Vector2i-Schlüssel, deshalb als Liste mit x und y.
func get_save_data() -> Array:
	var result := []
	for cell in _plants:
		result.append({
			"x": cell.x,
			"y": cell.y,
			"plant_id": _plants[cell]["plant_id"],
			"stage": _plants[cell]["stage"],
		})
	return result


func load_save_data(data: Array) -> void:
	var old_cells := _plants.keys()
	_plants.clear()
	for entry in data:
		var cell := Vector2i(int(entry["x"]), int(entry["y"]))
		_plants[cell] = {"plant_id": String(entry["plant_id"]), "stage": int(entry["stage"])}
	# Beete, die gerade angezeigt werden, auf den neuen Stand bringen.
	for cell in old_cells + _plants.keys():
		plant_changed.emit(cell)


func _on_day_passed(_day: int) -> void:
	# Erst für alle Beete entscheiden, dann wachsen lassen. Sonst hinge das
	# Ergebnis davon ab, in welcher Reihenfolge die Beete drankommen, sobald
	# Nachbarn sich gegenseitig beeinflussen (Nachtschatten).
	var growing: Array[Vector2i] = []
	for cell in _plants:
		if can_grow_tonight(cell):
			growing.append(cell)
	for cell in growing:
		grow(cell)
