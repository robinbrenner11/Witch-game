class_name RecipeData
extends Resource

## Ein Kesselrezept: zwei Zutaten (Reihenfolge egal) ergeben ein Item.
## Jedes Rezept ist eine Datei in data/recipes/ und wird im Kessel eingetragen.

@export var ingredient_a: String = ""
@export var ingredient_b: String = ""
@export var result_item_id: String = ""


func matches(first: String, second: String) -> bool:
	return (first == ingredient_a and second == ingredient_b) \
		or (first == ingredient_b and second == ingredient_a)
