## Nachtbilanz: NightLog zählt, was in der Nacht passiert ist, das Bett zeigt
## es vor dem Einschlafen (NightJournal). Neue Nacht = leere Bilanz.
extends TestCase


func before_each() -> void:
	SaveGame.new_game()
	TranslationServer.set_locale("de")


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_empty_night_shows_nothing() -> void:
	check(NightLog.is_empty(), "Nichts getan: keine Bilanz")


func test_counts_and_lines() -> void:
	for i in 3:
		Grimoire.report("forage", {"id": "moonmoss"})
	Grimoire.report("harvest", {"id": "mandrake"})
	Grimoire.report("brew", {"id": "potion_mending"})
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	Grimoire.report("talk", {"id": "watchman"})
	check_eq(NightLog.count("forage", "moonmoss"), 3, "Dreimal Mondmoos gezählt")
	check_eq(NightLog.count("forage"), 3, "Summe über alles Gesammelte")
	var text := "\n".join(NightLog.summary_lines())
	check(text.contains("Mondmoos ×3"), "Gesammeltes mit Anzahl: " + text)
	check(text.contains("Alraune"), "Geerntete Pflanze mit Pflanzennamen")
	check(text.contains("Heiltrank"), "Gebrautes")
	check(text.contains("Nachtwächter"), "Gesprächspartner")
	check(text.contains("Neu im Grimoire"), "Neue Einträge")
	check(NightLog.xp_gained("wildcraft") > 0, "Erfahrung seit Nachtbeginn")


func test_new_night_resets() -> void:
	Grimoire.report("forage", {"id": "moonmoss"})
	check(not NightLog.is_empty(), "Etwas passiert")
	DayCycle.sleep_until_night()
	check(NightLog.is_empty(), "Nach dem Schlafen beginnt eine leere Bilanz")
	check_eq(NightLog.xp_gained("wildcraft"), 0, "Erfahrung zählt ab der neuen Nacht")


func test_long_lists_are_shortened() -> void:
	for id in ["moonmoss", "willow_bark", "owl_feather", "dusk_berry", "ember_morel"]:
		Grimoire.report("forage", {"id": id})
	var gathered := NightLog.summary_lines()[0]
	check(gathered.contains("und 2 weitere"), "Höchstens drei Sorten, Rest gezählt: " + gathered)


## Die Seite passt mit einer vollen Nacht auf den Bildschirm (640×360).
func test_journal_fits_screen() -> void:
	for id in ["moonmoss", "willow_bark", "owl_feather", "dusk_berry", "ember_morel"]:
		Grimoire.report("forage", {"id": id})
		Grimoire.report("obtain", {"id": id})
	for npc in ["watchman", "gnarl", "ugo", "mother_moss"]:
		Grimoire.report("talk", {"id": npc})
	Grimoire.report("brew", {"id": "potion_mending"})
	Grimoire.report("plant", {"id": "mandrake"})
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	var journal := NightJournal.new()
	tree.root.add_child(journal)
	journal.show_lines("Nacht 8 · Vollmond", NightLog.summary_lines())
	await tree.process_frame
	await tree.process_frame
	var panel := journal._panel
	check(panel.size.y <= 340.0, "Seite %d px hoch, Bildschirm 360" % panel.size.y)
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	journal._unhandled_input(event)
	check(journal.is_showing(), "Direkt nach dem Öffnen nimmt sie noch keine Taste an")
	await tree.create_timer(NightJournal.MIN_SHOW_TIME + 0.1).timeout
	journal._unhandled_input(event)
	await tree.create_timer(NightJournal.FADE_TIME + 0.2).timeout
	check(not journal.is_showing(), "Danach schließt eine Taste die Seite")
	journal.queue_free()
	await tree.process_frame
