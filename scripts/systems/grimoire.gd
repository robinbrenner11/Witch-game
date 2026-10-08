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
signal level_up(discipline_id: String, level: int)
signal milestone_ready(discipline_id: String, level: int)

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
# Disziplin-ID -> gesammelte Erfahrung.
var _xp: Dictionary = {}
# Disziplin-ID -> {"5": Pfad-ID, "10": Pfad-ID}.
var _paths: Dictionary = {}
# "Aktion/Sache" -> true: Das erste Mal ist schon belohnt.
var _firsts: Dictionary = {}
# Rezept-Ergebnis-IDs, die eine Disziplin-Stufe beigebracht hat.
var _taught: Array[String] = []
# Aktion -> wie oft heute Nacht schon. Wird beim Schlafen geleert.
var _repeats: Dictionary = {}


func _ready() -> void:
	DayCycle.day_passed.connect(func(_day: int) -> void: _repeats.clear())


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
		report("page", {"id": page_id})
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
	if _taught.has(result_item_id):
		return true
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


# --- Disziplinen ---------------------------------------------------------------

## Andere Systeme melden nur, was passiert ist, z. B. report("harvest",
## {"id": "mandrake"}). Welche Disziplin wie viel Erfahrung bekommt, steht in
## den Disziplin-Dateien. Das erste Mal pro Sache bringt viel, Wiederholung in
## derselben Nacht immer weniger (Entdecken schlägt Wiederholen).
func report(action: String, details: Dictionary = {}) -> void:
	var subject := String(details.get("id", ""))
	var first_key := action + "/" + subject
	var count := int(_repeats.get(action, 0)) + 1
	_repeats[action] = count
	for discipline: DisciplineData in DisciplineData.all().values():
		var gained := 0
		if discipline.xp_small.has(action):
			gained += roundi(discipline.xp_small[action] * _repeat_factor(discipline, count))
		if discipline.xp_first.has(action) and not _firsts.has(first_key):
			gained += discipline.xp_first[action]
		if gained > 0:
			add_xp(discipline.id, gained)
	_firsts[first_key] = true


func _repeat_factor(discipline: DisciplineData, count: int) -> float:
	var factor := 1.0
	for threshold in discipline.repeat_thresholds:
		if count > threshold:
			factor *= 0.5
	return factor


func add_xp(discipline_id: String, amount: int) -> void:
	var discipline := DisciplineData.from_id(discipline_id)
	if discipline == null:
		return
	var before := level(discipline_id)
	_xp[discipline_id] = xp(discipline_id) + amount
	for new_level in range(before + 1, level(discipline_id) + 1):
		_on_level_reached(discipline, new_level)
	changed.emit()


func xp(discipline_id: String) -> int:
	return int(_xp.get(discipline_id, 0))


func level(discipline_id: String) -> int:
	var discipline := DisciplineData.from_id(discipline_id)
	return discipline.level_for(xp(discipline_id)) if discipline else 0


## Summe aller Disziplin-Stufen (docs/design/grimoire.md, Abschnitt 3).
func witch_strength() -> int:
	var total := 0
	for discipline_id: String in DisciplineData.all():
		total += level(discipline_id)
	return total


func _on_level_reached(discipline: DisciplineData, new_level: int) -> void:
	var reward := discipline.reward_for_level(new_level)
	if reward:
		_apply_reward(reward)
	Messages.post(tr("MSG_LEVEL_UP") % [tr("CHAPTER_" + discipline.id.to_upper()), new_level])
	level_up.emit(discipline.id, new_level)
	if new_level in discipline.milestone_levels:
		milestone_ready.emit(discipline.id, new_level)


## Werte (STAT) werden nicht hier angewendet, sondern abgefragt (get_stat).
func _apply_reward(reward: RewardData) -> void:
	match reward.type:
		RewardData.Type.ITEM:
			Inventory.add(reward.target_id, reward.value)
		RewardData.Type.RECIPE:
			if not _taught.has(reward.target_id):
				_taught.append(reward.target_id)
		RewardData.Type.XP:
			add_xp(reward.target_id, reward.value)


## Gewählter Pfad einer Disziplin auf einer Meilenstein-Stufe, sonst "".
func chosen_path(discipline_id: String, milestone: int) -> String:
	return String(_paths.get(discipline_id, {}).get(str(milestone), ""))


## Steht auf dieser Stufe eine Wahl aus? Dann glimmt das Lesezeichen.
func is_choice_pending(discipline_id: String, milestone: int) -> bool:
	return level(discipline_id) >= milestone and chosen_path(discipline_id, milestone) == ""


func can_choose(path: PathData) -> bool:
	if not is_choice_pending(path.discipline_id, path.level):
		return false
	var before := chosen_path(path.discipline_id, 5) if path.level > 5 else ""
	return PathData.options(path.discipline_id, path.level, before).has(path)


func choose_path(path: PathData) -> void:
	if not can_choose(path):
		return
	if not _paths.has(path.discipline_id):
		_paths[path.discipline_id] = {}
	_paths[path.discipline_id][str(path.level)] = path.id
	changed.emit()


## Ein Wert aus allen erreichten Stufen und gewählten Pfaden, z. B.
## get_stat("harvest_bonus") = Chance in Prozent auf eine Extra-Ernte.
## So bauen andere Systeme Boni ein, ohne die Disziplinen zu kennen.
func get_stat(stat: String) -> int:
	var total := 0
	for discipline: DisciplineData in DisciplineData.all().values():
		for reached in range(1, level(discipline.id) + 1):
			var reward := discipline.reward_for_level(reached)
			if reward and reward.type == RewardData.Type.STAT and reward.target_id == stat:
				total += reward.value
		for milestone in discipline.milestone_levels:
			var path := PathData.from_id(chosen_path(discipline.id, milestone))
			if path == null:
				continue
			for effect in path.effects:
				if effect.type == RewardData.Type.STAT and effect.target_id == stat:
					total += effect.value
	return total


## Würfelt eine Prozent-Chance aus get_stat, z. B. für Extra-Ernte.
func roll_stat(stat: String) -> bool:
	return randf() * 100.0 < get_stat(stat)


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
		"hints": _hints, "seen": _seen, "xp": _xp, "paths": _paths,
		"firsts": _firsts, "taught": _taught,
	}


func load_save_data(data: Dictionary) -> void:
	has_book = bool(data.get("has_book", false))
	_done_goals.assign(data.get("goals", []))
	_pages = data.get("pages", {}).duplicate(true)
	_hints = data.get("hints", {}).duplicate(true)
	_seen = data.get("seen", {}).duplicate(true)
	_xp = data.get("xp", {}).duplicate(true)
	_paths = data.get("paths", {}).duplicate(true)
	_firsts = data.get("firsts", {}).duplicate(true)
	_taught.assign(data.get("taught", []))
	_repeats.clear()
	changed.emit()
