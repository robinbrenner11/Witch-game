## Grimoire: Jede Doppelseite passt auf ihre Seiten, auf Englisch und Deutsch.
## Sonst läuft Text über die Seitenzahl, das Lesezeichen oder aus dem Buch.
## Geprüft wird ein gut gefüllter Stand (Buch, Gnarl umgezogen, ein paar
## Einträge entdeckt), weil volle Seiten am ehesten überlaufen.
extends TestCase

# Unten bleibt Platz für die Seitenzahl (siehe GrimoireBook._add_page_numbers).
const NUMBER_SPACE := 4.0


func before_each() -> void:
	SaveGame.new_game()
	Grimoire.find_book()
	WorldState.set_flag("gnarl_moved")
	for event: String in ["plant/mandrake", "forage/willow_bark", "obtain/bitterbloom_petal"]:
		var parts: PackedStringArray = event.split("/")
		Grimoire.report(parts[0], {"id": parts[1]})


func test_every_chapter_fits() -> void:
	var book := (load("res://scenes/ui/grimoire_book.tscn") as PackedScene).instantiate() as GrimoireBook
	tree.root.add_child(book)
	await tree.process_frame
	book.open("cover")
	var old_locale := TranslationServer.get_locale()
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for chapter in ChapterData.all():
			if not Grimoire.is_unlocked(chapter):
				continue
			book.go_to(chapter.id)
			book.refresh()
			await tree.process_frame
			await tree.process_frame
			for box in book._pages.get_children():
				if not box is VBoxContainer:
					continue
				var needed := (box as VBoxContainer).get_combined_minimum_size().y
				# Feste Seitenhöhe: Der Container selbst wächst mit seinem Inhalt mit.
				var room := BookStyle.LEFT_PAGE.size.y - BookStyle.PAGE_MARGIN * 2 - NUMBER_SPACE
				check(needed <= room, "%s (%s): Inhalt %d px, Platz %d px" % [chapter.id, locale, needed, room])
	TranslationServer.set_locale(old_locale)
	book.close()
	book.queue_free()
	await tree.process_frame
