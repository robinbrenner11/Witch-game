class_name EntryData
extends Resource

## Ein Eintrag im Herbarium (später auch Bestiary): eine Pflanze, ein
## Sammelfund, ein Wesen. Datei in data/grimoire/entries/. Er wird entdeckt,
## sobald etwas Bestimmtes passiert (z. B. das erste Pflanzen), und deckt
## dann nach und nach Fakten auf. Ist eine ganze Seite (page_group) voll,
## gibt es eine Belohnung. Design: docs/design/grimoire.md, Abschnitt 1.

const FOLDER := "res://data/grimoire/entries/"

static var _all: Array[EntryData] = []

@export var id: String = ""
# Kapitel-ID im Grimoire ("herbarium", "bestiary").
@export var chapter: String = "herbarium"
# Einträge mit derselben Gruppe stehen auf einer Seite (z. B. "garden", "woods").
@export var page_group: String = ""
@export var order: int = 0
# Schlüssel in data/translations/texts.csv.
@export var title_key: String = ""
@export var icon: Texture2D
# Items, die zu diesem Eintrag gehören. Ein Klick auf so eine Zutat im
# Rezept springt hierher.
@export var item_ids: Array[String] = []
# Ereignis, das den Eintrag entdeckt: "Aktion/Sache" wie bei Grimoire.report,
# z. B. "plant/mandrake".
@export var discover_on: String = ""
# Fakten (Schlüssel) und wann sie sich aufdecken: "" = gleich beim Entdecken,
# sonst "Aktion/Sache:Anzahl", z. B. "harvest/mandrake:5".
@export var facts: Array[String] = []
@export var fact_triggers: Array[String] = []
# Belohnung, wenn alle Einträge dieser Seite mit allen Fakten aufgedeckt sind.
# Steht nur bei einem Eintrag der Gruppe.
@export var page_reward: RewardData


static func all() -> Array[EntryData]:
	if _all.is_empty():
		for entry in DataFolder.load_all(FOLDER):
			_all.append(entry)
		_all.sort_custom(func(a: EntryData, b: EntryData) -> bool: return a.order < b.order)
	return _all


static func in_chapter(chapter_id: String) -> Array[EntryData]:
	return all().filter(func(e: EntryData) -> bool: return e.chapter == chapter_id)


static func for_item(item_id: String) -> EntryData:
	for entry in all():
		if entry.item_ids.has(item_id):
			return entry
	return null
