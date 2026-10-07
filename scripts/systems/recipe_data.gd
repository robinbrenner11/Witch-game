class_name RecipeData
extends Resource

## Ein Kesselrezept: eine Liste von Zutaten (Reihenfolge egal) ergibt ein Item.
## Jedes Rezept ist eine Datei in data/recipes/ und wird von dort automatisch
## geladen – ein neues Rezept ist also nur eine neue Datei.

const FOLDER := "res://data/recipes/"
# Alles, was kein Rezept ist (auch doppelte Zutaten), wird Hexenschlamm.
const FAILED_RESULT := "potion_sludge"

# Item-IDs, z. B. "crop_mandrake". Dieselbe Zutat darf mehrfach vorkommen.
@export var ingredients: Array[String] = []
@export var result_item_id: String = ""

# static: gehört zur Klasse, nicht zu einem einzelnen Rezept. So werden die
# Dateien nur einmal geladen, egal wie viele Kessel es gibt.
static var _all: Array[RecipeData] = []


## Was aus diesen Zutaten wird. Unbekannte Kombinationen ergeben Hexenschlamm.
static func result_for(given: Array[String]) -> String:
	for recipe in all():
		if recipe.matches(given):
			return recipe.result_item_id
	return FAILED_RESULT


static func all() -> Array[RecipeData]:
	if _all.is_empty():
		# list_directory funktioniert auch im exportierten Spiel, anders als
		# ein einfaches Durchsuchen des Ordners.
		for file in ResourceLoader.list_directory(FOLDER):
			if file.ends_with(".tres"):
				_all.append(load(FOLDER + file))
	return _all


## Reihenfolge egal: Beide Listen werden sortiert verglichen.
func matches(given: Array[String]) -> bool:
	var expected := ingredients.duplicate()
	var actual := given.duplicate()
	expected.sort()
	actual.sort()
	return expected == actual
