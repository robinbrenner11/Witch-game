## Der Kern-Kreislauf am Stück, über die echten Systeme (ohne Eingaben):
## Neues Spiel → Beete wecken und säen → Nächte schlafen → ernten → brauen →
## schlafen → Trank abholen. Dazwischen einmal Speichern und Laden über JSON,
## so wie die Spielstand-Datei es tut (ohne die echte Datei anzufassen).
extends TestCase

const GROWTH_RECIPE := ["crop_mandrake", "crop_ghost_fern"]


func before_each() -> void:
	SaveGame.new_game()


func test_new_game_start() -> void:
	check(Inventory.count("seed_mandrake") > 0 and Inventory.count("seed_ghost_fern") > 0, "Startsamen für das erste Rezept")
	check(not Grimoire.has_book, "Das Buch liegt noch auf dem Pult")
	check_eq(Grimoire.known_forms(), Grimoire.START_FORMS, "Startformen")
	check(Brewing.can_start(), "Kessel ist frei")


func test_plant_grow_harvest_brew() -> void:
	var cells := [Vector2i(17, 9), Vector2i(18, 9)]
	_sow(cells[0], "mandrake")
	_sow(cells[1], "ghost_fern")
	check_eq(Inventory.count("seed_mandrake"), 2, "Ein Samen verbraucht")

	# Halbzeit: speichern und laden, das Wachstum geht danach weiter.
	_sleep()
	_save_and_load()
	check(Garden.has_plant(cells[0]) and Garden.stage_at(cells[0]) == 1, "Pflanze übersteht Speichern und Laden")

	for night in 6:
		_sleep()
	for cell in cells:
		check(Garden.is_ripe(cell), "Nach einigen Nächten erntereif: %s" % Garden.plant_data_at(cell).id)
		_harvest(cell)
	check_eq(Inventory.count("crop_mandrake"), 1, "Alraune geerntet")
	check_eq(Inventory.count("crop_ghost_fern"), 1, "Geisterfarn geerntet")
	check_eq(Inventory.count("seed_mandrake"), 3, "Ernte gibt einen Samen zurück")

	var ingredients: Array[String] = []
	ingredients.assign(GROWTH_RECIPE)
	for item_id in ingredients:
		Inventory.remove(item_id)
	Brewing.start(ingredients)
	check(Brewing.is_brewing(), "Braut über Nacht")
	_save_and_load()
	check(Brewing.is_brewing(), "Brauen übersteht Speichern und Laden")
	_sleep()
	check_eq(Brewing.finished_potion(), "potion_growth", "Wachstumstrank ist fertig")
	check(Brewing.take_finished(), "Trank abgeholt")
	check(Inventory.count("potion_growth") >= 1, "Trank liegt in der Tasche")
	check(Grimoire.is_goal_done("brew"), "Ziel Brauen erledigt")


func test_save_roundtrip_keeps_everything() -> void:
	Inventory.add("cave_crystal", 2)
	WorldState.set_flag("gnarl_moved")
	WorldState.set_flag_next_night("test_pending")
	Grimoire.grant(load("res://data/trades/gnarl/b_staff_2.tres").reward)
	Brewing.raise_capacity(4)
	var before := SaveGame.collect()
	_save_and_load()
	check_eq(Inventory.count("cave_crystal"), 2, "Tasche")
	check(WorldState.has_flag("gnarl_moved"), "Flag")
	check(WorldState.is_pending("test_pending"), "Flag für die nächste Nacht")
	check_eq(Grimoire.upgrade_level("staff"), 2, "Upgrade")
	check_eq(Brewing.capacity, 4, "Kessel-Plätze")
	# Ein zweiter Durchlauf ergibt denselben Stand (nichts geht schleichend verloren).
	check_eq(JSON.stringify(_through_json(SaveGame.collect())), JSON.stringify(_through_json(before)), "Stabil über Speichern und Laden")


# --- Hilfen ---------------------------------------------------------------

func _sow(cell: Vector2i, plant_id: String) -> void:
	Garden.add_bed(cell)
	var plant := load("res://data/plants/%s.tres" % plant_id) as PlantData
	check(Inventory.remove(plant.seed_item_id), "Samen %s in der Tasche" % plant_id)
	Garden.plant_seed(cell, plant_id)


## Wie FarmTile.harvest, ohne Animation: Ernte und Samen in die Tasche.
func _harvest(cell: Vector2i) -> void:
	var data := Garden.plant_data_at(cell)
	Inventory.add(data.harvest_item_id)
	if data.seeds_on_harvest > 0:
		Inventory.add(data.seed_item_id, data.seeds_on_harvest)
	Garden.remove_plant(cell)


func _sleep() -> void:
	DayCycle.sleep_until_night()


## Wie Speichern und Laden über die Datei: durch JSON und zurück. Zahlen
## kommen dabei als Kommazahlen wieder, genau das soll hier mitgeprüft werden.
func _save_and_load() -> void:
	SaveGame._apply(_through_json(SaveGame.collect()))


func _through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))
