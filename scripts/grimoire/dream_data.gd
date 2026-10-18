class_name DreamData
extends Resource

## Ein Traum: eine Erinnerung von Vespera, die die Hexe beim Schlafen sieht,
## nachdem sie eine bestimmte Seite gelesen hat (PageData.dream_id) oder eine
## Belohnung vom Typ DREAM bekommen hat. Danach steht er als kurzer Eintrag
## im Journal. Datei in data/grimoire/dreams/<id>.tres.
## Design: docs/design/game_design.md, Abschnitt 9 (Wie erzählt wird).

const FOLDER := "res://data/grimoire/dreams/"

static var _all: Dictionary[String, DreamData] = {}

@export var id: String = ""
## Kurzer Titel für das Journal (Text-Schlüssel).
@export var title_key: String = ""
## Die Bilder des Traums, eins nach dem anderen (Text-Schlüssel).
@export var lines: Array[String] = []


static func from_id(dream_id: String) -> DreamData:
	return all().get(dream_id)


static func all() -> Dictionary[String, DreamData]:
	if _all.is_empty():
		for dream in DataFolder.load_all(FOLDER):
			_all[dream.id] = dream
	return _all
