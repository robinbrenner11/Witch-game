class_name GrimoireSpread
extends RefCounted

## Grundlage für eine aufgeschlagene Doppelseite eines Kapitels. Jede Vorlage
## (Innendeckel, Rezepte, später Disziplinen, Journal …) erbt davon und füllt
## die linke und rechte Seite. Das Buch baut die Doppelseite neu, wenn sich
## etwas ändert; der Zustand (z. B. der gewählte Eintrag) bleibt im Objekt.

var book: GrimoireBook
var chapter: ChapterData
# Breite des Textbereichs einer Seite.
var text_width := BookStyle.LEFT_PAGE.size.x - BookStyle.PAGE_MARGIN * 2


func _init(owner_book: GrimoireBook, for_chapter: ChapterData) -> void:
	book = owner_book
	chapter = for_chapter


## Füllt die beiden Seiten. Die Container sind leer und so groß wie der
## Textbereich der Seite.
func build(_left: Control, _right: Control) -> void:
	pass


## Blättern innerhalb des Kapitels (A/D). Gibt false zurück, wenn es in diese
## Richtung keine weitere Doppelseite gibt, dann blättert das Buch ins
## nächste Kapitel.
func flip(_direction: int) -> bool:
	return false


## Wie viele Seiten dieses Kapitel vor der aktuellen Doppelseite schon hat
## (für die Seitenzahlen, z. B. beim Blättern im Journal).
func page_offset() -> int:
	return 0


## Das Buch wird geschlossen oder die Seite verlassen. Hier z. B. Opfergaben
## zurück ins Inventar legen.
func on_close() -> void:
	pass


## Gibt es im Kapitel etwas, das noch nicht angesehen wurde? Dann glimmt das
## Lesezeichen.
func has_new() -> bool:
	return false


## Linke Seite: Kapiteltitel mit Goldlinie.
func add_title(page: Control) -> void:
	page.add_child(BookStyle.heading(chapter.title_key, BookStyle.INK_VESPERA_TITLE, text_width))
