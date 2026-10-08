extends Node

## Vesperas Grimoire: Spielstand des Buchs. Ob es gefunden ist, welche ersten
## Ziele erledigt sind, welche Seiten die Hexe hat, was sie über Rezepte weiß
## und was sie im Buch schon gesehen hat (Neues glimmt, bis es angesehen ist).
## Inhalte (Kapitel, Seiten …) stehen als Dateien in data/grimoire/; hier
## liegt nur, was sich im Spiel ändert. Design: docs/design/grimoire.md.
##
## Später kommen Disziplinen, Pfade und Einträge (Herbarium …) dazu. Andere
## Systeme melden dann nur Ereignisse (report), das Grimoire rechnet selbst.

signal changed
signal page_found(page_id: String)

# Die ersten Ziele auf dem Innendeckel, in der Reihenfolge von Vesperas Notiz.
const GOALS: Array[String] = ["plant", "brew", "sleep", "wake"]

var has_book := false
var _done_goals: Array[String] = []
# Seiten-ID -> {"fragments": int, "restored": bool}. Wer drinsteht, ist gefunden.
var _pages: Dictionary = {}
# Rezept-Ergebnis-ID -> Liste der Zutaten, die ein Gerücht verraten hat.
var _hints: Dictionary = {}
# Schlüssel (z. B. "recipe/potion_growth") -> true, schon im Buch angesehen.
var _seen: Dictionary = {}


func find_book() -> void:
	has_book = true
	changed.emit()


func complete_goal(goal: String) -> void:
	if not _done_goals.has(goal):
		_done_goals.append(goal)
		changed.emit()


func is_goal_done(goal: String) -> bool:
	return _done_goals.has(goal)


# --- Seiten ------------------------------------------------------------------

## Eine Seite aufgehoben. Bei zerrissenen Seiten zählt jedes Fragment.
func find_page(page_id: String) -> void:
	if not _pages.has(page_id):
		_pages[page_id] = {"fragments": 0, "restored": false}
	_pages[page_id]["fragments"] = int(_pages[page_id]["fragments"]) + 1
	page_found.emit(page_id)
	changed.emit()


func is_page_found(page_id: String) -> bool:
	return _pages.has(page_id)


## Lesbar: lose Seiten sofort, befallene nach dem Opfer, zerrissene, wenn alle
## Fragmente da sind.
func is_page_readable(page_id: String) -> bool:
	var page := PageData.from_id(page_id)
	if page == null or not _pages.has(page_id):
		return false
	match page.state:
		PageData.State.BLIGHTED:
			return bool(_pages[page_id]["restored"])
		PageData.State.FRAGMENTS:
			return int(_pages[page_id]["fragments"]) >= page.fragment_count
	return true


func restore_page(page_id: String) -> void:
	if _pages.has(page_id):
		_pages[page_id]["restored"] = true
		changed.emit()


# --- Rezepte -----------------------------------------------------------------

## Steht das Rezept auf einer lesbaren Seite?
func has_recipe_page(result_item_id: String) -> bool:
	for page_id: String in _pages:
		var page := PageData.from_id(page_id)
		if page and page.teaches_recipe(result_item_id) and is_page_readable(page_id):
			return true
	return false


## Bekannt, wenn die Hexe es schon gebraut oder auf einer Seite gelesen hat.
func knows_recipe(recipe: RecipeData) -> bool:
	return has_recipe_page(recipe.result_item_id) or Brewing.has_brewed(recipe.result_item_id)


## Selbst herausgefunden statt gelesen? Dann steht es in der Tinte der
## Spielerin (Magenta) statt in Vesperas (Bordeaux).
func learned_by_experiment(recipe: RecipeData) -> bool:
	return Brewing.has_brewed(recipe.result_item_id) and not has_recipe_page(recipe.result_item_id)


## Ein Gerücht verrät eine Zutat (von NPCs, später).
func hint_ingredient(result_item_id: String, ingredient_id: String) -> void:
	var known: Array = _hints.get(result_item_id, [])
	if not known.has(ingredient_id):
		known.append(ingredient_id)
		_hints[result_item_id] = known
		changed.emit()


func hinted_ingredients(result_item_id: String) -> Array:
	return _hints.get(result_item_id, [])


## Summe aller Disziplin-Stufen (docs/design/grimoire.md, Abschnitt 3).
func witch_strength() -> int:
	return 0


# --- Kapitel und Glimmen -----------------------------------------------------

## Bedingungen aus ChapterData.unlock. Unbekannte Bedingungen bleiben zu, bis
## das zugehörige System existiert (Kampf, Katze …).
func is_unlocked(chapter: ChapterData) -> bool:
	match chapter.unlock:
		"":
			return has_book
		"journal_page":
			for page_id: String in _pages:
				var page := PageData.from_id(page_id)
				if page and page.kind == PageData.Kind.JOURNAL:
					return true
			return false
	return false


func mark_seen(key: String) -> void:
	if not _seen.has(key):
		_seen[key] = true
		changed.emit()


func is_seen(key: String) -> bool:
	return _seen.has(key)


# --- Spielstand --------------------------------------------------------------

func reset() -> void:
	load_save_data({})


func get_save_data() -> Dictionary:
	return {
		"has_book": has_book, "goals": _done_goals, "pages": _pages,
		"hints": _hints, "seen": _seen,
	}


func load_save_data(data: Dictionary) -> void:
	has_book = bool(data.get("has_book", false))
	_done_goals.assign(data.get("goals", []))
	_pages = data.get("pages", {}).duplicate(true)
	_hints = data.get("hints", {}).duplicate(true)
	_seen = data.get("seen", {}).duplicate(true)
	changed.emit()
