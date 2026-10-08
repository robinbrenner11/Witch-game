class_name PathData
extends Resource

## Ein Hexenpfad: Auf Meilenstein-Stufen (5, 10) wählt man zwischen zwei
## Vorteilen. Die Optionen auf Stufe 10 hängen von der Wahl auf Stufe 5 ab.
## Datei in data/grimoire/paths/. Design: docs/design/grimoire.md, Abschnitt 3.

const FOLDER := "res://data/grimoire/paths/"

static var _all: Array[PathData] = []

@export var id: String = ""
@export var discipline_id: String = ""
@export var level: int = 5
# Nur für Stufe 10: dieser Pfad steht nur offen, wenn auf Stufe 5 der hier
# genannte gewählt wurde.
@export var requires_path_id: String = ""
# Schlüssel in data/translations/texts.csv (Name und Wirkung).
@export var title_key: String = ""
@export var description_key: String = ""
@export var effects: Array[RewardData] = []
# Was ein Wechsel am Lesepult kostet: Item-ID -> Anzahl (seltene Items).
@export var respec_cost: Dictionary[String, int] = {}


static func all() -> Array[PathData]:
	if _all.is_empty():
		for path in DataFolder.load_all(FOLDER):
			_all.append(path)
		_all.sort_custom(func(a: PathData, b: PathData) -> bool: return a.id < b.id)
	return _all


static func from_id(path_id: String) -> PathData:
	for path in all():
		if path.id == path_id:
			return path
	return null


## Die Wahlmöglichkeiten einer Disziplin auf einer Stufe. Für Stufe 10 nur die,
## die zur Wahl auf Stufe 5 passen.
static func options(discipline_id: String, level: int, chosen_before: String) -> Array[PathData]:
	var result: Array[PathData] = []
	for path in all():
		if path.discipline_id == discipline_id and path.level == level \
				and (path.requires_path_id == "" or path.requires_path_id == chosen_before):
			result.append(path)
	return result
