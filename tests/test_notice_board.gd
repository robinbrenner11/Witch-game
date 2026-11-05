## Anschlagbrett: Jede Seite passt in die Dialogbox (3 Zeilen), auf Englisch
## und Deutsch. Gemessen wird mit dem echten Textfeld der Box. Zettel-Text und
## „Gesucht/Lohn“ stehen auf getrennten Seiten.
extends TestCase

const MAX_LINES := 3


func before_each() -> void:
	SaveGame.new_game()


func test_note_and_status_are_separate_pages() -> void:
	var board := (load("res://scenes/world/notice_board.tscn") as PackedScene).instantiate()
	var pages: Array[String] = board.notes_pages()
	check_eq(pages.size(), Requests.active_ids().size() * 2, "Zwei Seiten pro Zettel")
	if pages.size() >= 2:
		check_eq(pages[0], Requests.get_request(Requests.active_ids()[0]).text_key, "Erst der Zettel-Text")
		check(pages[1].contains(Inventory.display_name_for(Requests.get_request(Requests.active_ids()[0]).item_id)), "Dann was gesucht ist")
	board.free()


func test_every_page_fits() -> void:
	var box := (load("res://scenes/ui/dialogue_box.tscn") as PackedScene).instantiate() as DialogueBox
	tree.root.add_child(box)
	await tree.process_frame
	var old_locale := TranslationServer.get_locale()
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for request: RequestData in DataFolder.load_all("res://data/requests/"):
			var wanted := tr("REQUEST_WANTED") % [request.amount, Inventory.display_name_for(request.item_id), 99]
			var status := "%s\n%s" % [wanted, tr("REQUEST_REWARD") % Requests.reward_text(request)]
			for text in [tr(request.text_key), tr(request.thanks_key), status]:
				box.text_label.text = text
				box.text_label.visible_characters = -1
				var lines := box.text_label.get_line_count()
				check(lines <= MAX_LINES, "%s (%s): %d Zeilen: %s" % [request.id, locale, lines, text.left(60)])
	TranslationServer.set_locale(old_locale)
	box.queue_free()
	await tree.process_frame
