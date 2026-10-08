class_name PageData
extends Resource

## Eine Seite aus Vesperas Grimoire, als Datei in data/grimoire/pages/.
## Jede Seite hat einen Lore-Schnipsel und genau eine Hauptbelohnung
## (docs/design/grimoire.md, Abschnitt 2).

const FOLDER := "res://data/grimoire/pages/"

enum Kind { RECIPE, JOURNAL, DIGITALIS, HINT }
# Wie man sie findet: lose (sofort lesbar), von der Bitterblüte befallen
# (erst nach einem Opfer am Lesepult) oder in Fragmente zerrissen.
enum State { LOOSE, BLIGHTED, FRAGMENTS }

static var _all: Dictionary[String, PageData] = {}

@export var id: String = ""
@export var kind: Kind = Kind.RECIPE
@export var state: State = State.LOOSE
# Nur bei FRAGMENTS: so viele Teile ergeben die ganze Seite.
@export var fragment_count: int = 1
# Nur bei BLIGHTED: Item-ID -> Anzahl, die am Lesepult geopfert werden.
@export var offering: Dictionary[String, int] = {}
# Mondphase, in der das Opfer gelingt (DayCycle.moon_phase()), -1 = egal.
@export var moon_condition: int = -1
@export var reward: RewardData
# Schlüssel in data/translations/texts.csv.
@export var lore_key: String = ""
# Platz im Kapitel Journal (Vesperas Zeitfolge).
@export var journal_order: int = 0
@export var dream_id: String = ""


static func from_id(page_id: String) -> PageData:
	return all().get(page_id)


static func all() -> Dictionary[String, PageData]:
	if _all.is_empty():
		for page in DataFolder.load_all(FOLDER):
			_all[page.id] = page
	return _all


## Bringt diese Seite das Rezept für dieses Item?
func teaches_recipe(result_item_id: String) -> bool:
	return reward != null and reward.type == RewardData.Type.RECIPE and reward.target_id == result_item_id
