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
# Seiten-ID -> {"parts": [Fragment-Nummern], "restored": bool, "rewarded": bool}.
# Wer drinsteht, ist gefunden (bei Fragmenten: mindestens ein Teil).
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
# "Aktion/Sache" -> wie oft insgesamt. Daraus ergibt sich, welche Einträge im
# Herbarium entdeckt und welche Fakten aufgedeckt sind.
var _counts: Dictionary = {}
# Seitengruppen (Herbarium), deren Belohnung es schon gab.
var _completed_groups: Array[String] = []
# "Disziplin/Stufe" -> true: Die Item-Belohnung dieser Stufe ist abgeholt.
var _claimed: Dictionary = {}


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

## Eine Seite (oder ein Teil davon) aufgehoben. fragment = welcher Teil einer
## zerrissenen Seite; bei ganzen Seiten 0.
func find_page(page_id: String, fragment: int = 0) -> void:
	if not _pages.has(page_id):
		_pages[page_id] = {"parts": [], "restored": false, "rewarded": false}
		report("page", {"id": page_id})
	var parts: Array = _pages[page_id]["parts"]
	if not parts.has(fragment):
		parts.append(fragment)
	page_found.emit(page_id)
	_check_readable(page_id)
	changed.emit()


func found_page_count() -> int:
	return _pages.size()


func is_page_found(page_id: String) -> bool:
	return _pages.has(page_id)


func has_fragment(page_id: String, fragment: int) -> bool:
	return _pages.has(page_id) and Array(_pages[page_id]["parts"]).has(fragment)


func fragments_found(page_id: String) -> int:
	return Array(_pages[page_id]["parts"]).size() if _pages.has(page_id) else 0


## Gefundene, aber noch befallene Seiten. Am Lesepult lassen sie sich mit
## einem Opfer wiederherstellen.
func blighted_pages() -> Array[String]:
	var result: Array[String] = []
	for page_id: String in _pages:
		var page := PageData.from_id(page_id)
		if page and page.state == PageData.State.BLIGHTED and not bool(_pages[page_id]["restored"]):
			result.append(page_id)
	return result


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
			return fragments_found(page_id) >= page.fragment_count
	return true


## Gelingt das Opfer jetzt? Mondbedingung der Seite, z. B. nur bei Vollmond.
func is_moon_right(page: PageData) -> bool:
	return page.moon_condition < 0 or DayCycle.moon_phase() == page.moon_condition


## Nach dem Opfer am Lesepult: Die Ranken welken, Vesperas Tinte kehrt zurück.
func restore_page(page_id: String) -> void:
	if _pages.has(page_id):
		_pages[page_id]["restored"] = true
		_check_readable(page_id)
		changed.emit()


## Wird eine Seite lesbar, gibt es einmal ihre Hauptbelohnung. Rezepte
## brauchen nichts extra: has_recipe_page() schaut selbst nach.
func _check_readable(page_id: String) -> void:
	if not is_page_readable(page_id) or bool(_pages[page_id].get("rewarded", false)):
		return
	_pages[page_id]["rewarded"] = true
	var page := PageData.from_id(page_id)
	if page.reward and page.reward.type != RewardData.Type.RECIPE:
		_apply_reward(page.reward)


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
	var was_discovered := _discovered_ids()
	_counts[first_key] = int(_counts.get(first_key, 0)) + 1
	for discipline: DisciplineData in DisciplineData.all().values():
		var gained := 0
		if discipline.xp_small.has(action):
			gained += roundi(discipline.xp_small[action] * _repeat_factor(discipline, count))
		if discipline.xp_first.has(action) and not _firsts.has(first_key):
			gained += discipline.xp_first[action]
		if gained > 0:
			add_xp(discipline.id, gained)
	_firsts[first_key] = true
	for entry in EntryData.all():
		if entry.discover_on == first_key and not was_discovered.has(entry.id):
			Messages.post(tr("MSG_ENTRY_DISCOVERED") % tr(entry.title_key))
	_check_completed_groups()
	changed.emit()


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


## Neue Stufe. Items holt man im Grimoire ab (so geht bei voller Tasche
## nichts verloren und man sieht, was man bekommt). Rezepte und Werte gelten
## sofort.
func _on_level_reached(discipline: DisciplineData, new_level: int) -> void:
	var reward := discipline.reward_for_level(new_level)
	if reward and reward.type != RewardData.Type.ITEM:
		_apply_reward(reward)
	Messages.post(tr("MSG_LEVEL_UP") % [tr("CHAPTER_" + discipline.id.to_upper()), new_level])
	if reward and reward.type == RewardData.Type.ITEM:
		Messages.post(tr("MSG_GIFT_WAITS"))
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


## Liegt auf dieser Stufe ein Geschenk zum Abholen bereit?
func is_reward_claimable(discipline_id: String, at_level: int) -> bool:
	var discipline := DisciplineData.from_id(discipline_id)
	var reward := discipline.reward_for_level(at_level) if discipline else null
	return reward != null and reward.type == RewardData.Type.ITEM \
		and level(discipline_id) >= at_level and not is_reward_claimed(discipline_id, at_level)


func is_reward_claimed(discipline_id: String, at_level: int) -> bool:
	return _claimed.has("%s/%d" % [discipline_id, at_level])


## Gibt false zurück, wenn die Tasche voll ist; dann bleibt es liegen.
func claim_reward(discipline_id: String, at_level: int) -> bool:
	if not is_reward_claimable(discipline_id, at_level):
		return false
	var reward := DisciplineData.from_id(discipline_id).reward_for_level(at_level)
	if not Inventory.has_room_for(reward.target_id, reward.value):
		Messages.post(tr("MSG_BAG_FULL"))
		return false
	Inventory.add(reward.target_id, reward.value)
	_claimed["%s/%d" % [discipline_id, at_level]] = true
	changed.emit()
	return true


## Wie viele Geschenke insgesamt auf Abholung warten.
func claimable_count(discipline_id: String = "") -> int:
	var count := 0
	for discipline: DisciplineData in DisciplineData.all().values():
		if discipline_id != "" and discipline.id != discipline_id:
			continue
		for at_level in range(1, level(discipline.id) + 1):
			if is_reward_claimable(discipline.id, at_level):
				count += 1
	return count


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


# --- Herbarium und Bestiary ------------------------------------------------------

func count_of(event: String) -> int:
	return int(_counts.get(event, 0))


func is_discovered(entry: EntryData) -> bool:
	return count_of(entry.discover_on) > 0


## Wie viele Fakten des Eintrags aufgedeckt sind. Fakten decken sich der Reihe
## nach auf; ein Auslöser "Aktion/Sache:Anzahl" zählt, sobald so oft passiert.
func revealed_facts(entry: EntryData) -> int:
	if not is_discovered(entry):
		return 0
	var revealed := 0
	for i in entry.facts.size():
		var trigger := entry.fact_triggers[i] if i < entry.fact_triggers.size() else ""
		if trigger != "":
			var parts := trigger.split(":")
			var needed := int(parts[1]) if parts.size() > 1 else 1
			if count_of(parts[0]) < needed:
				break
		revealed += 1
	return revealed


func is_entry_complete(entry: EntryData) -> bool:
	return revealed_facts(entry) >= entry.facts.size()


func is_group_complete(chapter_id: String, group: String) -> bool:
	for entry in EntryData.in_chapter(chapter_id):
		if entry.page_group == group and not is_entry_complete(entry):
			return false
	return true


func _discovered_ids() -> Array[String]:
	var result: Array[String] = []
	for entry in EntryData.all():
		if is_discovered(entry):
			result.append(entry.id)
	return result


## Volle Seiten im Herbarium bringen einmal ihre Belohnung.
func _check_completed_groups() -> void:
	for entry in EntryData.all():
		var key := entry.chapter + "/" + entry.page_group
		if entry.page_reward == null or _completed_groups.has(key):
			continue
		if is_group_complete(entry.chapter, entry.page_group):
			_completed_groups.append(key)
			_apply_reward(entry.page_reward)
			Messages.post(tr("MSG_PAGE_COMPLETE"))


## Pfadwechsel am Lesepult: kostet seltene Items (respec_cost des Pfads).
## Wer den Pfad auf Stufe 5 wechselt, verliert auch die Wahl auf Stufe 10,
## weil die Optionen dort davon abhängen.
func can_respec(discipline_id: String, milestone: int) -> bool:
	var path := PathData.from_id(chosen_path(discipline_id, milestone))
	if path == null:
		return false
	for item_id: String in path.respec_cost:
		if Inventory.count(item_id) < path.respec_cost[item_id]:
			return false
	return true


func respec(discipline_id: String, milestone: int) -> void:
	if not can_respec(discipline_id, milestone):
		return
	var path := PathData.from_id(chosen_path(discipline_id, milestone))
	for item_id: String in path.respec_cost:
		Inventory.remove(item_id, path.respec_cost[item_id])
	var chosen: Dictionary = _paths[discipline_id]
	chosen.erase(str(milestone))
	if milestone == 5:
		chosen.erase("10")
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


# --- Debug ----------------------------------------------------------------------

# Nur im Editor und in Debug-Exporten (wie N, F1, F2): F3 Erfahrung, F4 alle
# Seiten, F5 ganzes Herbarium.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_grimoire_xp"):
		has_book = true
		for discipline_id: String in DisciplineData.all():
			add_xp(discipline_id, 100)
	elif event.is_action_pressed("debug_grimoire_pages"):
		has_book = true
		for page: PageData in PageData.all().values():
			for part in page.fragment_count:
				find_page(page.id, part)
			restore_page(page.id)
		Messages.post("Debug: alle Seiten")
	elif event.is_action_pressed("debug_grimoire_entries"):
		for entry in EntryData.all():
			_counts[entry.discover_on] = maxi(count_of(entry.discover_on), 1)
			for trigger in entry.fact_triggers:
				if trigger != "":
					var parts := trigger.split(":")
					_counts[parts[0]] = maxi(count_of(parts[0]), int(parts[1]) if parts.size() > 1 else 1)
		_check_completed_groups()
		changed.emit()
		Messages.post("Debug: ganzes Herbarium")


# --- Spielstand --------------------------------------------------------------

func reset() -> void:
	load_save_data({})


func get_save_data() -> Dictionary:
	return {
		"has_book": has_book, "goals": _done_goals, "pages": _pages,
		"hints": _hints, "seen": _seen, "xp": _xp, "paths": _paths,
		"firsts": _firsts, "taught": _taught, "counts": _counts,
		"completed_groups": _completed_groups, "claimed": _claimed,
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
	_counts = data.get("counts", {}).duplicate(true)
	_completed_groups.assign(data.get("completed_groups", []))
	_claimed = data.get("claimed", {}).duplicate(true)
	_repeats.clear()
	changed.emit()
