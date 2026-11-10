extends Node

## Merkt sich, was in der laufenden Nacht passiert ist (gesammelt, gebraut,
## gereinigt, entdeckt, Erfahrung), damit das Bett vor dem Einschlafen eine
## kurze Bilanz zeigen kann (NightJournal). Nur die vergangene Nacht: Was über
## Tag wächst, soll man weiter selbst im Garten entdecken.
##
## Gespeichert wird es zusammen mit der Nacht: Wer mitten in der Nacht über
## das Pausemenü speichert und später fortsetzt, bekommt beim Schlafen die
## Bilanz der ganzen Nacht, nicht nur der zweiten Hälfte.

# Was zu „Gesammelt“ zählt, und wie viele Sorten höchstens genannt werden.
const GATHER_ACTIONS: Array[String] = ["forage", "harvest", "obtain"]
const MAX_NAMES := 3

# action -> {subject -> Anzahl}
var _events: Dictionary = {}
var _xp_at_start: Dictionary = {}
var _levels: Dictionary = {}
var _discovered: Array[String] = []
var _pages := 0


func _ready() -> void:
	Grimoire.reported.connect(_on_reported)
	Grimoire.entry_discovered.connect(func(entry: EntryData) -> void: _discovered.append(entry.title_key))
	Grimoire.level_up.connect(func(discipline_id: String, new_level: int) -> void: _levels[discipline_id] = new_level)
	Grimoire.page_found.connect(func(_page_id: String) -> void: _pages += 1)
	DayCycle.day_passed.connect(func(_day: int) -> void: reset())
	reset()


## Neue Nacht, neues Spiel oder geladener Stand: von vorn zählen.
func reset() -> void:
	_events.clear()
	_levels.clear()
	_discovered.clear()
	_pages = 0
	_xp_at_start.clear()
	for id: String in DisciplineData.all():
		_xp_at_start[id] = Grimoire.xp(id)


func get_save_data() -> Dictionary:
	return {
		"day": DayCycle.day, "events": _events.duplicate(true),
		"xp_at_start": _xp_at_start.duplicate(), "levels": _levels.duplicate(),
		"discovered": _discovered.duplicate(), "pages": _pages,
	}


## Übernimmt nur einen Stand aus genau dieser Nacht (DayCycle und Grimoire
## sind beim Laden schon dran gewesen), sonst beginnt die Bilanz leer.
func load_save_data(data: Dictionary) -> void:
	reset()
	if int(data.get("day", -1)) != DayCycle.day:
		return
	var events: Variant = data.get("events", {})
	if events is Dictionary:
		for action in events:
			if not action is String or not events[action] is Dictionary:
				continue
			var by_subject := {}
			for subject in events[action]:
				var n: Variant = events[action][subject]
				if subject is String and (n is float or n is int) and int(n) > 0:
					by_subject[subject] = int(n)
			if not by_subject.is_empty():
				_events[action] = by_subject
	var xp: Variant = data.get("xp_at_start", {})
	if xp is Dictionary:
		for id: String in _xp_at_start:
			if xp.get(id) is float or xp.get(id) is int:
				# Nie mehr als der heutige Stand: sonst gäbe es „negative“ Erfahrung.
				_xp_at_start[id] = clampi(int(xp[id]), 0, Grimoire.xp(id))
	var levels: Variant = data.get("levels", {})
	if levels is Dictionary:
		for id in levels:
			if id is String and _xp_at_start.has(id) and (levels[id] is float or levels[id] is int):
				_levels[id] = int(levels[id])
	var discovered: Variant = data.get("discovered", [])
	if discovered is Array:
		for key in discovered:
			if key is String and key != "":
				_discovered.append(key)
	var pages: Variant = data.get("pages", 0)
	if pages is float or pages is int:
		_pages = maxi(int(pages), 0)


func count(action: String, subject: String = "") -> int:
	var by_subject: Dictionary = _events.get(action, {})
	if subject != "":
		return int(by_subject.get(subject, 0))
	var total := 0
	for n: int in by_subject.values():
		total += n
	return total


func xp_gained(discipline_id: String) -> int:
	return Grimoire.xp(discipline_id) - int(_xp_at_start.get(discipline_id, 0))


func is_empty() -> bool:
	return summary_lines().is_empty()


## Die Bilanz als fertige, übersetzte Zeilen (leer, wenn nichts passiert ist).
func summary_lines() -> Array[String]:
	var lines: Array[String] = []
	var gathered := _merged(GATHER_ACTIONS)
	if not gathered.is_empty():
		lines.append(tr("NIGHTLOG_GATHERED") % _name_list(gathered))
	var brewed := _merged(["brew"])
	if not brewed.is_empty():
		lines.append(tr("NIGHTLOG_BREWED") % _name_list(brewed))
	if count("plant") > 0:
		lines.append(tr("NIGHTLOG_PLANTED") % count("plant"))
	if count("cleanse") > 0:
		lines.append(tr("NIGHTLOG_CLEANSED") % count("cleanse"))
	var met: Array[String] = []
	for npc_id: String in _events.get("talk", {}):
		met.append(tr("NPC_" + npc_id.to_upper()))
	if not met.is_empty():
		lines.append(tr("NIGHTLOG_MET") % ", ".join(met))
	var found: Array[String] = []
	for key in _discovered.slice(0, MAX_NAMES):
		found.append(tr(key))
	var text := ", ".join(found)
	if _discovered.size() > MAX_NAMES:
		text += " " + tr("NIGHTLOG_MORE") % (_discovered.size() - MAX_NAMES)
	if _pages > 0:
		text += (", " if text != "" else "") + tr("NIGHTLOG_PAGES") % _pages
	if text != "":
		lines.append(tr("NIGHTLOG_DISCOVERED") % text)
	var xp_parts: Array[String] = []
	for chapter in ChapterData.all():
		var gained := xp_gained(chapter.id)
		if gained <= 0:
			continue
		var part := "%s +%d" % [tr(chapter.title_key), gained]
		if _levels.has(chapter.id):
			part += " " + tr("NIGHTLOG_LEVEL") % _levels[chapter.id]
		xp_parts.append(part)
	if not xp_parts.is_empty():
		lines.append(tr("NIGHTLOG_XP") % ", ".join(xp_parts))
	return lines


func _on_reported(action: String, subject: String) -> void:
	var by_subject: Dictionary = _events.get_or_add(action, {})
	by_subject[subject] = int(by_subject.get(subject, 0)) + 1


## Mehrere Aktionen zusammengefasst, Schlüssel = Anzeigename.
func _merged(actions: Array[String]) -> Dictionary:
	var result := {}
	for action in actions:
		for subject: String in _events.get(action, {}):
			var key := _display_name(action, subject)
			result[key] = int(result.get(key, 0)) + int(_events[action][subject])
	return result


func _display_name(action: String, subject: String) -> String:
	# Geerntet wird eine Pflanze (PLANT_…), sonst ist es ein Item.
	if action == "harvest":
		return tr("PLANT_" + subject.to_upper())
	return tr("ITEM_" + subject.to_upper())


## „Mondmoos ×3, Weidenrinde ×2 und 2 weitere“, häufigste zuerst.
func _name_list(counts: Dictionary) -> String:
	var names: Array = counts.keys()
	names.sort_custom(func(a: Variant, b: Variant) -> bool: return counts[a] > counts[b])
	var parts: Array[String] = []
	for name: String in names.slice(0, MAX_NAMES):
		var n := int(counts[name])
		parts.append(name if n == 1 else "%s ×%d" % [name, n])
	var text := ", ".join(parts)
	if names.size() > MAX_NAMES:
		text += " " + tr("NIGHTLOG_MORE") % (names.size() - MAX_NAMES)
	return text
