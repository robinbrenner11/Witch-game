class_name ChapterData
extends Resource

## Ein Kapitel im Grimoire (Lesezeichen am Buchrand), als Datei in
## data/grimoire/chapters/. Reihenfolge und Gruppen stehen hier, damit neue
## Kapitel keinen Code brauchen (docs/design/grimoire.md, Abschnitt 1).

const FOLDER := "res://data/grimoire/chapters/"

enum Group { COVER, TOOL, DISCIPLINE, WORLD }
# Welche Seitenvorlage das Buch für das Kapitel benutzt.
enum Template { COVER, INDEX_DETAIL, DISCIPLINE, JOURNAL }

static var _all: Array[ChapterData] = []

@export var id: String = ""
# Schlüssel in data/translations/texts.csv.
@export var title_key: String = ""
@export var group: Group = Group.TOOL
@export var order: int = 0
@export var tab_color: Color = Color.WHITE
@export var template: Template = Template.INDEX_DETAIL
# Ab wann das Kapitel offen ist. Grimoire.is_unlocked() kennt die Bedingungen:
# "" = sobald das Buch gefunden ist, sonst z. B. "combat", "cat", "journal_page".
@export var unlock: String = ""


## Alle Kapitel in Buchreihenfolge.
static func all() -> Array[ChapterData]:
	if _all.is_empty():
		for chapter in DataFolder.load_all(FOLDER):
			_all.append(chapter)
		_all.sort_custom(func(a: ChapterData, b: ChapterData) -> bool: return a.order < b.order)
	return _all
