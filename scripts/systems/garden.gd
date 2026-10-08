extends Node

## Wo im Garten Beete sind und was darin wächst. Läuft als Autoload, damit der Garten auch dann
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
# Kommt, wenn ein Beet angelegt oder entfernt wurde ("Erde wecken").
signal bed_changed(cell: Vector2i)

const TILE_SIZE := 32

# Zelle -> {"plant_id": String, "stage": int}. Bewusst ein einfaches
# Dictionary statt eigener Klasse: lässt sich direkt speichern.
var _plants: Dictionary[Vector2i, Dictionary] = {}
# Welche Zellen Beete sind. Ein Dictionary als Menge: nur die Schlüssel zählen.
var _beds: Dictionary[Vector2i, bool] = {}
# false = noch nie festgelegt; dann übernimmt der Garten beim ersten Laden die
# Beete, die in der Szene von Hand gesetzt sind (Startbeete).
var beds_initialized := false


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)


## Rechnet eine Weltposition in die Zelle um, in der sie liegt.
static func cell_at(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / TILE_SIZE).floor())


func has_bed(cell: Vector2i) -> bool:
	return _beds.has(cell)


func bed_cells() -> Array[Vector2i]:
	return _beds.keys()


func add_bed(cell: Vector2i) -> void:
	if not has_bed(cell):
		_beds[cell] = true
		bed_changed.emit(cell)


## Nur leere Beete lassen sich entfernen.
func remove_bed(cell: Vector2i) -> bool:
	if not has_bed(cell) or has_plant(cell):
		return false
	_beds.erase(cell)
	bed_changed.emit(cell)
	return true


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
## (Hexenschlamm, Wachstumstrank); das natürliche Wachstum läuft über
## can_grow_tonight().
func grow(cell: Vector2i) -> void:
	if not has_plant(cell) or is_ripe(cell):
		return
	_plants[cell]["stage"] += 1
	plant_changed.emit(cell)


## Magie im Bereich: alle Pflanzen bis radius Felder um center wachsen um
## stages Stufen (radius 0 = nur center, 1 = 3×3). Gibt false zurück, wenn
## dort nichts wachsen konnte, damit der Trank nicht verschwendet wird.
func grow_area(center: Vector2i, radius: int, stages: int = 1) -> bool:
	var any_grew := false
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if grow_by_magic(center + Vector2i(x, y), stages):
				any_grew = true
	return any_grew


## Würde grow_area() hier etwas wachsen lassen? Ändert nichts. So kann die
## Hexe vor dem Ausgießen prüfen, ob sich der Trank lohnt.
func can_grow_area(center: Vector2i, radius: int) -> bool:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if can_grow_by_magic(center + Vector2i(x, y)):
				return true
	return false


## Magie setzt sich über Auren und Nachtregeln hinweg, aber manche Pflanzen
## lassen sich von ihr nicht reif machen (Mondkelch).
func can_grow_by_magic(cell: Vector2i) -> bool:
	if not has_plant(cell) or is_ripe(cell):
		return false
	var data := plant_data_at(cell)
	return data.magic_can_ripen or stage_at(cell) < data.stage_count - 2


func grow_by_magic(cell: Vector2i, stages: int) -> bool:
	var grew := false
	for i in stages:
		if not can_grow_by_magic(cell):
			break
		grow(cell)
		grew = true
	return grew


## Natürliches Wachstum über Nacht. Es kann blockiert sein (Auren, Mond),
## Magie über grow() setzt sich darüber hinweg. Hier docken später weitere
## Bedingungen an (Blutrose ab Stufe 3 usw.).
func can_grow_tonight(cell: Vector2i) -> bool:
	return not is_ripe(cell) and not is_growth_blocked(cell) and not is_waiting_for_full_moon(cell)


## Steht die Pflanze kurz vor der Reife und braucht dafür den Vollmond, der
## heute Nacht nicht da ist? Gewachsen wird beim Beginn der Nacht, also zählt
## die Mondphase der neuen Nacht.
func is_waiting_for_full_moon(cell: Vector2i) -> bool:
	var data := plant_data_at(cell)
	return data != null and data.ripens_only_at_full_moon 		and stage_at(cell) == data.stage_count - 2 and not Moon.is_full()


## Liegt das Beet im Bereich einer hemmenden Aura (Nachtschatten)? Die
## Pflanze zeigt das durch Welken, auch wenn sie schon reif ist.
func is_growth_blocked(cell: Vector2i) -> bool:
	if not has_plant(cell):
		return false
	for source_cell in active_aura_cells(PlantData.AuraEffect.BLOCK_GROWTH):
		if _aura_reaches(source_cell, cell):
			return true
	return false


## Alle Beete, deren Pflanze gerade eine Aura dieser Art ausstrahlt. Braucht
## später auch die Kuppel, um zu wissen, wo sie hingehört.
func active_aura_cells(effect: PlantData.AuraEffect) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in _plants:
		var data := plant_data_at(cell)
		if data.aura_effect == effect and stage_at(cell) >= data.aura_min_stage:
			result.append(cell)
	return result


func _aura_reaches(source_cell: Vector2i, target_cell: Vector2i) -> bool:
	if source_cell == target_cell:
		return false
	var source := plant_data_at(source_cell)
	if not source.aura_affects_own_kind and source == plant_data_at(target_cell):
		return false
	# Größerer Abstand auf einer Achse zählt, so ist der Bereich ein Quadrat.
	var distance := (target_cell - source_cell).abs()
	return maxi(distance.x, distance.y) <= source.aura_radius


## Neues Spiel: alle Beete leer.
func reset() -> void:
	load_save_data({})


## JSON kennt keine Vector2i-Schlüssel, deshalb als Listen mit x und y.
func get_save_data() -> Dictionary:
	var plants := []
	for cell in _plants:
		plants.append({
			"x": cell.x,
			"y": cell.y,
			"plant_id": _plants[cell]["plant_id"],
			"stage": _plants[cell]["stage"],
		})
	var beds := []
	for cell in _beds:
		beds.append({"x": cell.x, "y": cell.y})
	return {"plants": plants, "beds": beds, "beds_initialized": beds_initialized}


func load_save_data(data: Variant) -> void:
	# Ältere Spielstände speicherten nur die Pflanzen als Liste.
	if data is Array:
		data = {"plants": data}
	var old_plants := _plants.keys()
	var old_beds := _beds.keys()
	_plants.clear()
	_beds.clear()
	for entry in data.get("plants", []):
		var cell := Vector2i(int(entry["x"]), int(entry["y"]))
		_plants[cell] = {"plant_id": String(entry["plant_id"]), "stage": int(entry["stage"])}
	for entry in data.get("beds", []):
		_beds[Vector2i(int(entry["x"]), int(entry["y"]))] = true
	beds_initialized = bool(data.get("beds_initialized", false))
	# Beete und Pflanzen, die gerade angezeigt werden, auf den neuen Stand bringen.
	for cell in old_beds + _beds.keys():
		bed_changed.emit(cell)
	for cell in old_plants + _plants.keys():
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
