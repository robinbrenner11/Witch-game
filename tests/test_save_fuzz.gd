## Fuzz-Test für das Laden: Jeder Wert im Spielstand wird der Reihe nach durch
## etwas Falsches ersetzt (anderer Typ, Unsinn, fehlt ganz). Danach wird der
## Stand geladen und das Spiel benutzt die Daten (neue Nacht, Abfragen, Orte).
## Dabei darf nie ein Skriptfehler oder Engine-Fehler entstehen: Ein System, das
## mitten im Laden abbricht, wäre halb geladen. Warnungen sind erlaubt und
## erwünscht (die Systeme sollen melden, was sie aussortieren).
##
## Die oberste Ebene (Typ jedes Teils) prüft SaveGame.is_valid(), siehe
## test_save_robustness.gd. Hier geht es um alles darunter.
extends TestCase

const CAVE := "res://scenes/world/waterfall_cave.tscn"
# Womit jeder Wert ersetzt wird. Bewusst auch „fast richtige“ Werte: negative
# und riesige Zahlen, unbekannte Namen, falsch gefüllte Listen.
const WRONG: Array = [
	null, true, -1, 3.7, 1.0e9, 1.0e300, "", "quatsch", [], [1, "a", null, {}, [[]]], {}, {"a": 1, "b": [2]},
]
# Mehr als so viele kaputte Stellen werden nicht einzeln gemeldet.
const MAX_REPORTED := 12
# Welche Systeme die Daten eines Teils lesen (siehe _use). Die Uhr hängt an
# allem: Mond, Dialoge, Gesuche und Nacht-Merker richten sich nach der Nacht.
const USES := {
	"day_cycle": ["time", "inventory", "garden", "brewing", "grimoire", "world", "requests", "night_log"],
	"inventory": ["inventory", "brewing", "requests"],
	"garden": ["garden"],
	"brewing": ["brewing"],
	"grimoire": ["grimoire", "brewing", "world", "night_log"],
	"wilds": [],
	"world": ["world", "requests"],
	"requests": ["requests"],
	"night_log": ["night_log"],
	"player": [],
}
const STATS := ["harvest_bonus", "seed_bonus", "brew_bonus", "brew_count", "forage_bonus", "ward_health", "hexblade", "hexcaster", "pagefinder", "seeker"]
const NPCS := ["watchman", "mother_moss", "ugo", "gnarl"]

var _holder: Node
var _base: Dictionary = {}
var _problems: PackedStringArray = []
var _mutations := 0
var _started := 0
# Tauschangebote je NPC, einmal geladen (TradeOffer.all_for liest jedes Mal den Ordner).
var _offers := {}
# Festgehalten, sonst liest load() die Szene bei jeder Verfälschung neu.
var _cave_scene: PackedScene = load(CAVE)


func before_each() -> void:
	SaveGame.new_game()
	if _offers.is_empty():
		for npc in NPCS:
			_offers[npc] = TradeOffer.all_for(npc)
	_holder = Node.new()
	tree.root.add_child(_holder)
	_problems = []
	_mutations = 0


func after_each() -> void:
	_holder.queue_free()
	await tree.process_frame
	SaveGame.new_game()


# --- Ein Test pro Teil des Spielstands, damit man sieht, wo es klemmt ---

func test_day_cycle() -> void:
	await _fuzz_part("day_cycle")


func test_inventory() -> void:
	await _fuzz_part("inventory")


func test_garden() -> void:
	await _fuzz_part("garden")


func test_brewing() -> void:
	await _fuzz_part("brewing")


func test_grimoire() -> void:
	await _fuzz_part("grimoire")


func test_wilds() -> void:
	await _fuzz_part("wilds")


func test_world() -> void:
	await _fuzz_part("world")


func test_requests() -> void:
	await _fuzz_part("requests")


func test_night_log() -> void:
	await _fuzz_part("night_log")


func test_player() -> void:
	await _fuzz_part("player")


## Der unveränderte Stand lädt ohne jede Meldung, auch ohne Warnung. Sonst
## würde der Fuzz-Test oben Fehler des Grundzustands den Mutationen zuschreiben.
func test_base_state_loads_cleanly() -> void:
	await _build_base()
	for part: String in USES:
		await _load_and_use(_base, part)
	var logged := take_logged()
	check(logged.is_empty(), "Unveränderter Stand: nichts protokolliert (%d Meldungen)" % logged.size())
	for entry in logged.slice(0, 3):
		check(false, String(entry["text"]) + " [" + String(entry["where"]) + "]")


## Nach kaputten Daten gelten weiter vernünftige Grenzen.
func test_values_stay_sane() -> void:
	await _build_base()
	var data := _base.duplicate(true)
	data["day_cycle"] = {"day": -5, "minutes": 99999.0, "night_slowdown": -3}
	data["inventory"]["chest_capacity"] = 1.0e9
	data["inventory"]["selected_slot"] = -7
	data["brewing"]["capacity"] = 1.0e9
	data["player"]["vitals"] = {"health": 1.0e9, "power": -50}
	allow_warnings()
	SaveGame.new_game()
	SaveGame._apply(data)
	check(DayCycle.day >= 1, "Nacht mindestens 1 (ist %d)" % DayCycle.day)
	check(DayCycle.minutes >= 0.0 and DayCycle.minutes < DayCycle.MINUTES_PER_DAY, "Uhrzeit im Tag")
	check(DayCycle.night_slowdown >= 1.0, "Nacht nie schneller als normal")
	check(Inventory.chest_capacity <= Inventory.CHEST_MAX, "Truhe höchstens %d Plätze" % Inventory.CHEST_MAX)
	check(Inventory.selected_slot >= 0 and Inventory.selected_slot < Inventory.SIZE, "Gewählter Platz in der Tasche (ist %d)" % Inventory.selected_slot)
	check(Brewing.capacity >= Brewing.START_CAPACITY and Brewing.capacity <= Brewing.MAX_CAPACITY, "Kessel-Plätze im erlaubten Bereich (ist %d)" % Brewing.capacity)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	_holder.add_child(player)
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	check(vitals.health >= 1 and vitals.health <= vitals.max_hp(), "Leben zwischen 1 und Maximum (ist %d)" % vitals.health)
	check(vitals.power >= 0.0 and vitals.power <= vitals.max_power(), "Hexenkraft zwischen 0 und Maximum")


# --- Ablauf ---

func _fuzz_part(part: String) -> void:
	allow_warnings()
	_started = Time.get_ticks_msec()
	await _build_base()
	var paths: Array = []
	_collect_paths(_base[part], [part], paths)
	check(paths.size() >= 2, "%s: Stand hat Inhalt zum Verfälschen (%d Stellen)" % [part, paths.size()])
	for path: Array in paths:
		var original: Variant = _value_at(_base, path)
		# Fehlt ganz.
		await _try(part, path, null, true)
		for wrong: Variant in WRONG:
			if typeof(wrong) == typeof(original) and wrong == original:
				continue
			await _try(part, path, wrong, false)
	print("    %s: %d Stellen, %d Verfälschungen, %.1f s" % [part, paths.size(), _mutations, (Time.get_ticks_msec() - _started) / 1000.0])
	check(_problems.is_empty(), "%s: %d von %d Verfälschungen führten zu Fehlern" % [part, _problems.size(), _mutations])
	for line in _problems.slice(0, MAX_REPORTED):
		check(false, line)


func _try(part: String, path: Array, wrong: Variant, remove: bool) -> void:
	var data := _base.duplicate(true)
	var parent: Variant = _value_at(data, path.slice(0, -1))
	var key: Variant = path[-1]
	if remove:
		if parent is Dictionary:
			parent.erase(key)
		else:
			parent.remove_at(key)
	else:
		parent[key] = wrong
	_mutations += 1
	take_logged()
	# Die Höhle nur laden, wenn gerade ihre eigenen Wildwuchs-Daten verfälscht sind.
	await _load_and_use(data, part, part != "wilds" or String(path[1]).begins_with("waterfall_cave"))
	for entry in take_logged():
		if not entry["warning"]:
			_problems.append("%s %s → %s [%s]" % [
				"/".join(path.map(func(p: Variant) -> String: return str(p))),
				"fehlt" if remove else "= " + JSON.stringify(wrong).left(30),
				String(entry["text"]).left(110), String(entry["where"]).get_file()])
			return


## Lädt den Stand wie „Fortsetzen“ und benutzt ihn dann so, wie das Spiel es
## täte. Was teuer ist (Orte, Hexe), nur für den Teil, der gerade dran ist.
func _load_and_use(data: Dictionary, part: String, with_place: bool = true) -> void:
	SaveGame.new_game()
	if not SaveGame.is_valid(data):
		return
	SaveGame._apply(data)
	var level: Node = null
	if part == "wilds" and with_place:
		level = _cave_scene.instantiate()
		_holder.add_child(level)
		await tree.process_frame
	if part == "player":
		var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
		_holder.add_child(player)
		player.get_save_data()
		player.free()
	_use(part)
	# Eine neue Nacht: Wachstum, Kessel, Nachwachsen, Gesuche, Merker.
	DayCycle.sleep_until_night()
	_use(part)
	# Was geladen wurde, muss sich auch wieder speichern und laden lassen.
	var again: Variant = JSON.parse_string(JSON.stringify(SaveGame.collect()))
	if again is Dictionary and SaveGame.is_valid(again):
		SaveGame._apply(again)
	if level:
		level.free()


## Fragt die Systeme so ab, wie HUD, Grimoire und Welt es tun. Je Teil des
## Spielstands nur die Systeme, die seine Daten lesen (USES): Alles bei jeder
## Verfälschung abzufragen, dauerte ein Vielfaches.
func _use(part: String) -> void:
	for system: String in USES.get(part, []):
		call("_use_" + system)


func _use_time() -> void:
	DayCycle.night_factor()
	DayCycle.is_daytime()
	Moon.phase_name()
	Moon.nights_until(Moon.Phase.FULL)


func _use_inventory() -> void:
	for slot in Inventory.SIZE + Inventory.CHEST_MAX:
		var item_id := Inventory.item_in_slot(slot)
		Inventory.count_in_slot(slot)
		if item_id != "":
			Inventory.display_name_for(item_id)
			Inventory.icon_for(item_id)
			Inventory.max_stack(item_id)
	Inventory.selected_item_id()
	Inventory.count("wild_herb")
	Inventory.has_room_for("wild_herb", 3)


func _use_garden() -> void:
	for cell in Garden.bed_cells():
		Garden.has_plant(cell)
		Garden.plant_data_at(cell)
		Garden.stage_at(cell)
		Garden.is_ripe(cell)
		Garden.can_grow_tonight(cell)
		Garden.is_growth_blocked(cell)
		Garden.is_waiting_for_full_moon(cell)


func _use_brewing() -> void:
	Brewing.is_brewing()
	Brewing.brewing_ingredients()
	Brewing.finished_potion()
	Brewing.can_start()
	Brewing.pinned_recipe()
	for recipe in RecipeData.all():
		Brewing.known_result(recipe.ingredients)
		Brewing.brew_count(recipe.result_item_id)
		Grimoire.knows_recipe(recipe)
		Grimoire.learned_by_experiment(recipe)
		Grimoire.has_recipe_page(recipe.result_item_id)
		Grimoire.hinted_ingredients(recipe.result_item_id)
		SpreadRecipes.state_of(recipe)
		SpreadRecipes.is_ready(recipe)


func _use_grimoire() -> void:
	Grimoire.witch_strength()
	Grimoire.found_page_count()
	Grimoire.blighted_pages()
	Grimoire.known_forms()
	for goal in Grimoire.GOALS:
		Grimoire.is_goal_done(goal)
	for page_id: String in PageData.all():
		Grimoire.is_page_found(page_id)
		Grimoire.fragments_found(page_id)
		Grimoire.has_fragment(page_id, 0)
		Grimoire.is_page_readable(page_id)
	for chapter in ChapterData.all():
		Grimoire.is_unlocked(chapter)
	for discipline: DisciplineData in DisciplineData.all().values():
		Grimoire.xp(discipline.id)
		var level := Grimoire.level(discipline.id)
		Grimoire.claimable_count(discipline.id)
		for at_level in range(1, discipline.max_level + 1):
			Grimoire.is_reward_claimable(discipline.id, at_level)
			Grimoire.is_reward_claimed(discipline.id, at_level)
		for milestone in discipline.milestone_levels:
			var chosen := Grimoire.chosen_path(discipline.id, milestone)
			Grimoire.is_choice_pending(discipline.id, milestone)
			Grimoire.can_respec(discipline.id, milestone)
			for path in PathData.options(discipline.id, milestone, Grimoire.chosen_path(discipline.id, 5) if milestone > 5 else ""):
				Grimoire.can_choose(path)
			check(chosen == "" or level >= milestone, "Kein Pfad ohne die Stufe dafür")
	for stat in STATS:
		Grimoire.get_stat(stat)
	for entry in EntryData.all():
		Grimoire.is_discovered(entry)
		Grimoire.revealed_facts(entry)
		Grimoire.is_entry_complete(entry)
	for form_id in Grimoire.known_forms():
		DigitalisForm.at_level(form_id, Grimoire.upgrade_level(form_id))
	Grimoire.upgrade_level("cauldron")
	Grimoire.report("forage", {"id": "moonmoss"})
	Grimoire.mark_seen("fuzz")


func _use_world() -> void:
	WorldState.has_flag("met_watchman")
	WorldState.did_tonight("watchman/rumor")
	WorldState.times_tonight("surge/forest/beetles")
	WorldState.is_pending("gnarl_moved")
	for npc in NPCS:
		DialogueData.pick(npc, "")
		DialogueData.pick(npc, "rumor")
		for offer: TradeOffer in _offers[npc]:
			offer.is_offered(npc)
			offer.times_tonight(npc)


func _use_requests() -> void:
	for id in Requests.active_ids():
		Requests.get_request(id)
		Requests.can_deliver(id)
		Requests.done_count(id)
	Requests.deliverable_ids()


func _use_night_log() -> void:
	NightLog.summary_lines()
	NightLog.is_empty()
	for discipline_id: String in DisciplineData.all():
		NightLog.xp_gained(discipline_id)


# --- Grundzustand: ein Stand, in dem jedes System etwas zu speichern hat ---

func _build_base() -> void:
	SaveGame.new_game()
	DayCycle.day = 9
	DayCycle.minutes = 23.5 * 60
	DayCycle.lengthen_night(1.5)
	Grimoire.find_book()
	Grimoire.witch_name = "Nyx"
	for item in [["wild_herb", 5], ["potion_mending", 2], ["moonmoss", 3], ["crop_ghost_fern", 2], ["crop_lantern_berry", 2]]:
		Inventory.add(item[0], item[1])
	Inventory.transfer(0)
	for i in 3:
		var cell := Garden.cell_at(Vector2(560 + 32 * i, 304))
		Garden.add_bed(cell)
		Garden.plant_seed(cell, ["mandrake", "nightshade", "moon_chalice"][i])
		Garden.grow(cell)
	Brewing.learn(["crop_ghost_fern", "crop_lantern_berry"], "potion_mending")
	Brewing.toggle_pin("potion_mending")
	var brew: Array[String] = ["crop_ghost_fern", "crop_lantern_berry"]
	Brewing.start(brew)
	Brewing.toggle_pin("potion_ember_bomb")
	for page_id: String in PageData.all():
		Grimoire.find_page(page_id)
	Grimoire.hint_ingredient("potion_ember_bomb", "ember_morel")
	for event in ["plant/mandrake", "harvest/mandrake", "forage/moonmoss", "forage/willow_bark", "cleanse/blight_beetle", "talk/watchman", "visit/Forest", "brew/potion_mending"]:
		var parts: PackedStringArray = event.split("/")
		for i in 3:
			Grimoire.report(parts[0], {"id": parts[1]})
	for discipline_id: String in DisciplineData.all():
		Grimoire.add_xp(discipline_id, 400)
	Grimoire.claim_reward("wildcraft", 1)
	Grimoire.choose_path(PathData.from_id("herbalism_wildheart"))
	Grimoire.choose_path(PathData.from_id("warding_hexblade"))
	Grimoire.mark_seen("level/herbalism/1")
	Grimoire.complete_goal("plant")
	Grimoire.grant(load("res://data/trades/gnarl/b_staff_2.tres").reward)
	for flag in ["met_watchman", "met_gnarl", "gnarl_helped"]:
		WorldState.set_flag(flag)
	WorldState.set_flag_next_night("gnarl_moved")
	WorldState.mark_tonight("watchman/rumor")
	WorldState.add_tonight("surge/forest/beetles")
	# Gesuch erfüllen, damit auch „erledigt“ gefüllt ist.
	for id in Requests.active_ids():
		var request := Requests.get_request(id)
		Inventory.add(request.item_id, request.amount)
		if Requests.deliver(id):
			break
	# Wildwuchs: die Höhle einmal besuchen, einen Kristall pflücken (Zustand
	# am Stück), und ein Ort mit Nachwachs-Uhren.
	var cave := _cave_scene.instantiate()
	_holder.add_child(cave)
	await tree.process_frame
	await tree.process_frame
	for place: String in ["waterfall_cave/crystals"]:
		for id: String in Wilds.items(place):
			Wilds.item_state(place, id)["regrow_in"] = 2
			break
	cave.free()
	Wilds.register("fuzz/respawn", {"mode": "respawn", "max": 4, "pause": 1, "respawn_nights": 2, "chance": 0.5})
	var gone := Wilds.add_item("fuzz/respawn", "res://scenes/world/wild/ember_morel.tscn", Vector2(100, 100))
	Wilds.add_item("fuzz/respawn", "res://scenes/world/wild/ember_morel.tscn", Vector2(140, 100))
	Wilds.remove_item("fuzz/respawn", gone)
	SaveGame._player_data = {"vitals": {"health": 4, "power": 2.5}, "effects": {"active": ["wisp", "dusk"]}}
	_base = JSON.parse_string(JSON.stringify(SaveGame.collect()))
	take_logged()


# --- Hilfen ---

## Alle Stellen unter value, an denen etwas verfälscht wird. Bei langen,
## gleichförmigen Listen und Tabellen reichen die ersten zwei Einträge.
func _collect_paths(value: Variant, path: Array, out: Array) -> void:
	var keys: Array = []
	if value is Dictionary:
		keys = value.keys()
	elif value is Array:
		keys = range(value.size())
	else:
		return
	if keys.size() > 4 and _same_type(value, keys):
		keys = keys.slice(0, 2)
	for key: Variant in keys:
		out.append(path + [key])
		_collect_paths(value[key], path + [key], out)


func _same_type(container: Variant, keys: Array) -> bool:
	var first := typeof(container[keys[0]])
	for key: Variant in keys:
		if typeof(container[key]) != first:
			return false
	return true


func _value_at(root: Variant, path: Array) -> Variant:
	var value: Variant = root
	for key: Variant in path:
		value = value[key]
	return value
