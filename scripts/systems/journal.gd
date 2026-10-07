extends Node

## Das Rezeptbuch der alten Hexe: ob die Hexe es gefunden hat, welche losen
## Seiten sie aufgehoben hat und welche der ersten Ziele erledigt sind. Die
## Ziele stehen als Notiz der alten Hexe auf der ersten Buchseite und werden
## durchgestrichen, sobald sie erledigt sind – keine Quest-Liste.

signal changed

# IDs der ersten Ziele, in der Reihenfolge der Notiz.
const GOALS: Array[String] = ["plant", "brew", "sleep"]

var has_book := false
# Ergebnis-IDs der Rezepte, deren lose Seite gefunden wurde.
var _found_pages: Array[String] = []
var _done_goals: Array[String] = []


func find_book() -> void:
	has_book = true
	changed.emit()


func find_page(result_item_id: String) -> void:
	if not _found_pages.has(result_item_id):
		_found_pages.append(result_item_id)
		changed.emit()


func is_page_found(result_item_id: String) -> bool:
	return _found_pages.has(result_item_id)


## Ein Rezept steht im Buch, wenn die Hexe es schon gebraut oder seine Seite
## gefunden hat.
func knows_recipe(recipe: RecipeData) -> bool:
	return is_page_found(recipe.result_item_id) or Brewing.has_brewed(recipe.result_item_id)


func complete_goal(goal: String) -> void:
	if not _done_goals.has(goal):
		_done_goals.append(goal)
		changed.emit()


func is_goal_done(goal: String) -> bool:
	return _done_goals.has(goal)


func reset() -> void:
	load_save_data({})


func get_save_data() -> Dictionary:
	return {"has_book": has_book, "pages": _found_pages, "goals": _done_goals}


func load_save_data(data: Dictionary) -> void:
	has_book = bool(data.get("has_book", false))
	_found_pages.clear()
	for page in data.get("pages", []):
		_found_pages.append(String(page))
	_done_goals.clear()
	for goal in data.get("goals", []):
		_done_goals.append(String(goal))
	changed.emit()
