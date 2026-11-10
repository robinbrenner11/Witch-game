## Absicherung der Befunde aus der externen Code-Prüfung (06.11.2026):
## 1 Speichern meldet Erfolg/Fehler, „Speichern und beenden“ bleibt bei Fehler.
## 2 Fortsetzen stellt Leben, Hexenkraft, Trankwirkungen, Ewige Nacht wieder her.
## 3 Sortenwechsel beim Zielen bricht das Zielen ab, nur Wurftränke fliegen.
## 4 Strukturell beschädigte Stände werden vor dem Anwenden abgewiesen.
## 5 Die XP-Abschwächung pro Nacht übersteht Speichern und Laden.
## 6 (eigener Fund, 10.11.) Was „heute Nacht schon war“ übersteht Speichern und
##   Fortsetzen: Mondwasser-Limit, Tausch-Limits, für die Nacht geöffnete Gates,
##   Neumond-Käfer, Nachtbuch.
## Alle Dateien liegen in user://test_save/, der echte Spielstand bleibt unberührt.
extends TestCase

const DIR := "user://test_save/"

var _holder: Node


func before_each() -> void:
	SaveGame.new_game()
	_clean_dir()
	DirAccess.make_dir_recursive_absolute(DIR)
	SaveGame.save_path = DIR + "save.json"
	SaveGame.temp_path = DIR + "save.json.tmp"
	SaveGame.backup_path = DIR + "save.json.bak"
	_holder = Node.new()
	tree.root.add_child(_holder)


func after_each() -> void:
	_holder.queue_free()
	await tree.process_frame
	SaveGame.save_path = SaveGame.SAVE_PATH
	SaveGame.temp_path = SaveGame.TEMP_PATH
	SaveGame.backup_path = SaveGame.BACKUP_PATH
	_clean_dir()


func _clean_dir() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for sub in DirAccess.get_directories_at(DIR):
		for file in DirAccess.get_files_at(DIR + sub):
			DirAccess.remove_absolute(DIR + sub + "/" + file)
		DirAccess.remove_absolute(DIR + sub)
	for file in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + file)


## Ein Ordner an der Stelle einer Datei: Schreiben bzw. Umbenennen scheitert.
func _block(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
	var file := FileAccess.open(path + "/inhalt", FileAccess.WRITE)
	file.store_string("x")
	file.close()


## Wie „Speichern und beenden“ und danach „Fortsetzen“: Der Stand geht einmal
## durch JSON (dort werden aus ganzen Zahlen Kommazahlen), dazwischen beginnt
## ein neues Spiel, damit nichts im Speicher überlebt.
func _save_and_continue() -> void:
	var text := JSON.stringify(SaveGame.collect())
	SaveGame.new_game()
	SaveGame._apply(JSON.parse_string(text))


func _player() -> Player:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	_holder.add_child(player)
	return player


# --- 1 ---

func test_save_reports_success_and_failure() -> void:
	check(SaveGame.save_game(), "Normales Speichern meldet Erfolg")
	check(FileAccess.file_exists(SaveGame.save_path), "Datei liegt da")
	var before := FileAccess.get_file_as_string(SaveGame.save_path)
	Inventory.add("wild_herb", 3)
	_block(SaveGame.temp_path)
	expect_error("Spielstand konnte nicht gespeichert werden")
	check(not SaveGame.save_game(), "Zwischendatei nicht schreibbar: Fehler gemeldet")
	check_eq(FileAccess.get_file_as_string(SaveGame.save_path), before, "Alter Stand unverändert")


func test_failed_swap_is_reported_and_keeps_a_save() -> void:
	check(SaveGame.save_game(), "Erster Stand")
	SaveGame.save_path = DIR + "blocked"
	_block(SaveGame.save_path)
	expect_error("fehlgeschlagen")
	check(not SaveGame.save_game(), "Tausch scheitert: Fehler statt „gespeichert“")


func test_save_and_quit_stays_open_on_failure() -> void:
	var menu := (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate()
	_holder.add_child(menu)
	await tree.process_frame
	_block(SaveGame.temp_path)
	expect_error("Spielstand konnte nicht gespeichert werden")
	var scene_before := tree.current_scene
	menu._on_save_quit_button_pressed()
	await tree.process_frame
	check(tree.current_scene == scene_before, "Kein Wechsel zum Titel")
	var label := menu.find_child("SaveError", true, false) as Label
	check(label != null and label.visible and label.text != "", "Menü sagt, dass nichts gespeichert wurde")
	tree.paused = false


# --- 2 ---

func test_resume_restores_player_state() -> void:
	var player := _player()
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	vitals.health = 4
	vitals.power = 2.5
	var effects := player.get_node("PotionEffects") as PotionEffects
	effects.load_save_data({"active": ["moonlight", "dusk"]})
	DayCycle.lengthen_night(1.5)
	var text := JSON.stringify(SaveGame.collect())
	player.free()
	SaveGame.new_game()
	SaveGame._apply(JSON.parse_string(text))
	var again := _player()
	await tree.process_frame
	var vitals2 := again.get_node("Vitals") as Vitals
	var effects2 := again.get_node("PotionEffects") as PotionEffects
	check_eq(vitals2.health, 4, "Leben wie beim Speichern, nicht voll")
	# Im Frame nach dem Start lädt sie schon ein wenig nach.
	check(vitals2.power >= 2.5 and vitals2.power < 3.0, "Hexenkraft wie beim Speichern (ist %.2f)" % vitals2.power)
	check(effects2.is_active("moonlight"), "Flüssiges Mondlicht wirkt weiter")
	check(effects2.is_active("dusk"), "Dämmertrank wirkt weiter")
	check(not effects2.is_active("wisp"), "Nicht getrunkenes bleibt aus")
	check(effects2.is_active("endless_night"), "Ewige Nacht hält an")


func test_new_game_starts_fresh() -> void:
	SaveGame._apply(SaveGame.collect().merged({"player": {"vitals": {"health": 2}}}, true))
	SaveGame.new_game()
	var player := _player()
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	check_eq(vitals.health, vitals.max_hp(), "Neues Spiel: volle Lebenspunkte")


# --- 3 ---

func test_switching_while_aiming_cancels_throw() -> void:
	var player := _player()
	await tree.process_frame
	Inventory.add("potion_ember_bomb", 1)
	Inventory.add("potion_mending", 1)
	var potions := player.get_node("CombatPotions") as CombatPotions
	# Ohne Ort gilt die Umgebung als sicher; der Kampfmodus wird direkt gesetzt.
	(player.get_node("Combat") as Combat).active = true
	potions.selected_id = "potion_ember_bomb"
	potions._use_selected()
	check(potions.is_aiming(), "Zielt mit der Glutbombe")
	potions.select_next()
	check(not potions.is_aiming(), "Sortenwechsel beendet das Zielen")
	check_eq(potions.selected_id, "potion_mending", "Heiltrank gewählt")
	potions._throw()
	check_eq(Inventory.count("potion_mending"), 1, "Heiltrank wird nie geworfen")


# --- 4 ---

func test_structurally_broken_saves_are_rejected() -> void:
	var good := SaveGame.collect()
	check(SaveGame.is_valid(good), "Gültiger Stand")
	check(not SaveGame.is_valid(good.merged({"inventory": []}, true)), "Inventar als Liste: abgewiesen")
	check(not SaveGame.is_valid(good.merged({"day_cycle": []}, true)), "Tageszyklus als Liste: abgewiesen")
	check(not SaveGame.is_valid(good.merged({"brewing": "kaputt"}, true)), "Kessel als Text: abgewiesen")
	check(not SaveGame.is_valid(good.merged({"player": 3}, true)), "Hexe als Zahl: abgewiesen")
	var no_garden := good.duplicate()
	no_garden.erase("garden")
	check(not SaveGame.is_valid(no_garden), "Garten fehlt: abgewiesen")
	check(SaveGame.is_valid(good.merged({"garden": []}, true)), "Alter Garten als Liste bleibt erlaubt")


func test_broken_save_falls_back_to_backup() -> void:
	Inventory.add("moonmoss", 2)
	check(SaveGame.save_game(), "Erster Stand")
	Inventory.add("moonmoss", 5)
	check(SaveGame.save_game(), "Zweiter Stand, erster wird Backup")
	# Letzten Stand strukturell beschädigen: gültiges JSON, falscher Typ.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveGame.save_path))
	data["inventory"] = []
	var file := FileAccess.open(SaveGame.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	SaveGame.new_game()
	expect_error("Teile fehlen oder haben den falschen Typ")
	expect_error("lade den vorletzten")
	check(SaveGame.load_game(), "Laden gelingt über das Backup")
	check_eq(Inventory.count("moonmoss"), 2, "Stand aus dem Backup, nichts halb übernommen")


# --- 5 ---

func test_repeat_penalty_survives_reload() -> void:
	for i in 30:
		Grimoire.report("forage", {"id": "moonmoss"})
	var saved := Grimoire.get_save_data()
	var before := Grimoire.xp("wildcraft")
	Grimoire.report("forage", {"id": "moonmoss"})
	var tired_gain := Grimoire.xp("wildcraft") - before
	Grimoire.load_save_data(saved)
	before = Grimoire.xp("wildcraft")
	Grimoire.report("forage", {"id": "moonmoss"})
	check_eq(Grimoire.xp("wildcraft") - before, tired_gain, "Gleiche Nacht: weiter abgeschwächt")
	DayCycle.sleep_until_night()
	Grimoire.load_save_data(saved)
	before = Grimoire.xp("wildcraft")
	Grimoire.report("forage", {"id": "moonmoss"})
	check(Grimoire.xp("wildcraft") - before > tired_gain, "Stand aus einer anderen Nacht: wieder volle Erfahrung")


# --- 6 ---

func test_moon_water_limit_survives_continue() -> void:
	DayCycle.day = 8
	check(Moon.is_full(), "Nacht 8 ist Vollmond")
	var spot := MoonWaterSpot.new()
	_holder.add_child(spot)
	for i in MoonWaterSpot.PER_NIGHT:
		WorldState.mark_tonight("moon_water/%d" % i)
	check_eq(spot._left_tonight(), 0, "Alle Portionen geschöpft")
	_save_and_continue()
	check_eq(spot._left_tonight(), 0, "Nach dem Fortsetzen in derselben Nacht bleibt es dabei")
	DayCycle.sleep_until_night()
	check_eq(spot._left_tonight(), MoonWaterSpot.PER_NIGHT, "In der nächsten Nacht wieder voll")


func test_trade_limit_survives_continue() -> void:
	var offer := load("res://data/trades/mother_moss/c_bark_for_chalice.tres") as TradeOffer
	check(offer.per_night > 0, "Angebot mit Limit pro Nacht")
	WorldState.mark_tonight(offer._night_key("mother_moss", 0))
	check_eq(offer.times_tonight("mother_moss"), 1, "Einmal getauscht")
	_save_and_continue()
	check_eq(offer.times_tonight("mother_moss"), 1, "Fortsetzen setzt das Limit nicht zurück")


func test_gate_opened_tonight_survives_continue() -> void:
	var forest := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate()
	_holder.add_child(forest)
	await tree.process_frame
	var mist := forest.get_node("BloomMist") as Gate
	check(mist.on_potion(ItemData.from_id("potion_cleansing_mist")), "Reinigungsnebel lichtet den Nebel")
	forest.free()
	_save_and_continue()
	var again := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate()
	_holder.add_child(again)
	await tree.process_frame
	check((again.get_node("BloomMist") as Gate).is_open(), "Nach dem Fortsetzen in derselben Nacht noch offen (Trank ist ja verbraucht)")
	again.free()


func test_surge_count_survives_continue() -> void:
	var growth := WildGrowth.new()
	growth._place = "forest/beetles"
	growth._on_surge_taken()
	growth._on_surge_taken()
	check_eq(WorldState.times_tonight(growth._surge_key()), 2, "Zwei Neumond-Käfer gereinigt")
	_save_and_continue()
	check_eq(WorldState.times_tonight(growth._surge_key()), 2, "Sie kommen nach dem Fortsetzen nicht wieder")
	growth.free()
	DayCycle.sleep_until_night()
	check_eq(WorldState.times_tonight("surge/forest/beetles"), 0, "Neue Nacht, neuer Zähler")


func test_night_log_survives_continue() -> void:
	TranslationServer.set_locale("de")
	for i in 3:
		Grimoire.report("forage", {"id": "moonmoss"})
	Grimoire.report("talk", {"id": "watchman"})
	var before := NightLog.summary_lines()
	check(not before.is_empty(), "Bilanz gefüllt")
	_save_and_continue()
	check_eq(NightLog.count("forage", "moonmoss"), 3, "Gezähltes bleibt")
	check_eq(NightLog.summary_lines(), before, "Gleiche Bilanz wie vor dem Speichern")
	TranslationServer.set_locale("en")


func test_tonight_from_another_night_is_dropped() -> void:
	WorldState.mark_tonight("watchman/rumor")
	Grimoire.report("forage", {"id": "moonmoss"})
	var text := JSON.stringify(SaveGame.collect())
	SaveGame.new_game()
	var data: Dictionary = JSON.parse_string(text)
	# Ein Stand, dessen Nacht-Merker nicht zur gespeicherten Nacht passen.
	data["world"]["tonight_day"] = 99
	data["night_log"]["day"] = 99
	SaveGame._apply(data)
	check(not WorldState.did_tonight("watchman/rumor"), "Merker aus einer anderen Nacht gelten nicht")
	check(NightLog.is_empty(), "Bilanz aus einer anderen Nacht gilt nicht")


func test_old_save_without_night_parts_loads() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.collect()))
	data.erase("night_log")
	data.erase("player")
	(data["world"] as Dictionary).erase("tonight")
	check(SaveGame.is_valid(data), "Älterer Stand ohne die neuen Teile ist gültig")
	SaveGame._apply(data)
	check(NightLog.is_empty(), "Leere Bilanz")
