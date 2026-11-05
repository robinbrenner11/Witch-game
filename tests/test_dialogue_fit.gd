## Alle Gesprächszeilen aller NPCs passen in die Dialogbox (höchstens 3
## Zeilen), auf Englisch und Deutsch. Gemessen mit dem echten Textfeld der Box
## in voller Breite (bisher hat kein NPC ein Porträt; mit Porträt wird die Zeile
## schmaler, dann diesen Test erweitern).
extends TestCase

const MAX_LINES := 3


func test_all_dialogue_lines_fit() -> void:
	var box := (load("res://scenes/ui/dialogue_box.tscn") as PackedScene).instantiate() as DialogueBox
	tree.root.add_child(box)
	await tree.process_frame
	var keys: Array[String] = []
	for folder in DirAccess.get_directories_at("res://data/dialogue/"):
		for dialogue: DialogueData in DataFolder.load_all("res://data/dialogue/%s/" % folder):
			for key in dialogue.lines:
				if not keys.has(key):
					keys.append(key)
	check(keys.size() > 30, "Gesprächszeilen gefunden (%d)" % keys.size())
	var old_locale := TranslationServer.get_locale()
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for key in keys:
			box.text_label.text = tr(key)
			box.text_label.visible_characters = -1
			var lines := box.text_label.get_line_count()
			check(lines <= MAX_LINES, "%s (%s): %d Zeilen" % [key, locale, lines])
	TranslationServer.set_locale(old_locale)
	box.queue_free()
	await tree.process_frame
