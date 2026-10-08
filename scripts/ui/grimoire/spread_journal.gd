class_name SpreadJournal
extends GrimoireSpread

## Vesperas Tagebuch: feste Plätze in ihrer Zeitfolge, zwei Seiten pro
## Doppelseite. Fehlende Seiten sind ausgerissene Stummel mit einem halben
## Wort als Hinweis, befallene sind überwuchert, zerrissene zeigen, wie viel
## schon da ist. Frisch lesbare Seiten schreiben sich langsam hinein.
## Design: docs/design/grimoire.md, Abschnitte 1 (Journal) und 4 (Animationen).

# Sekunden, bis eine neu lesbare Seite ganz dasteht.
const INK_TIME := 2.0

var _first := 0


static func journal_pages() -> Array[PageData]:
	var result: Array[PageData] = []
	for page: PageData in PageData.all().values():
		if page.kind == PageData.Kind.JOURNAL:
			result.append(page)
	result.sort_custom(func(a: PageData, b: PageData) -> bool: return a.journal_order < b.journal_order)
	return result


static func seen_key(page: PageData) -> String:
	return "page/" + page.id


func has_new() -> bool:
	for page in journal_pages():
		if Grimoire.is_page_readable(page.id) and not Grimoire.is_seen(seen_key(page)):
			return true
	return false


func flip(direction: int) -> bool:
	var next := _first + direction * 2
	if next < 0 or next >= journal_pages().size():
		return false
	_first = next
	return true


func build(left: Control, right: Control) -> void:
	var pages := journal_pages()
	for i in 2:
		var box: Control = left if i == 0 else right
		if i == 0:
			add_title(box)
		if _first + i < pages.size():
			_build_entry(box, pages[_first + i], i == 0)


func _build_entry(box: Control, page: PageData, is_left: bool) -> void:
	if not Grimoire.is_page_found(page.id):
		var stub := TornStub.new()
		stub.fold_on_right = is_left
		stub.hint = tr(page.stub_hint_key) if page.stub_hint_key != "" else ""
		_cover_page(box, stub)
		return
	if page.state == PageData.State.BLIGHTED and not Grimoire.is_page_readable(page.id):
		box.add_child(BookStyle.label("BOOK_PAGE_BLIGHTED", BookStyle.INK_FAINT, text_width))
		box.add_child(BookStyle.label("BOOK_RESTORE_AT_LECTERN", BookStyle.INK_FAINT, text_width))
		var vines := SpreadBlank.Vines.new()
		vines.seed_value = page.id.hash()
		_cover_page(box, vines)
		return
	var text := tr(page.lore_key)
	if not Grimoire.is_page_readable(page.id):
		# Zerrissen: nur der Anteil der Wörter, dessen Teile schon da sind.
		var words := text.split(" ")
		var shown := words.size() * Grimoire.fragments_found(page.id) / maxi(page.fragment_count, 1)
		box.add_child(BookStyle.label(tr("BOOK_FRAGMENTS") % [Grimoire.fragments_found(page.id), page.fragment_count], BookStyle.INK_FAINT))
		box.add_child(BookStyle.label(" ".join(words.slice(0, shown)), BookStyle.INK_VESPERA, text_width))
		return
	var lore := BookStyle.label(text, BookStyle.INK_VESPERA, text_width)
	box.add_child(lore)
	if not Grimoire.is_seen(seen_key(page)):
		# Vesperas Tinte kehrt Zeichen für Zeichen zurück.
		lore.visible_ratio = 0.0
		lore.create_tween().tween_property(lore, "visible_ratio", 1.0, INK_TIME)
		Grimoire.mark_seen(seen_key(page))


## Legt eine Zeichnung über die ganze Seite (Stummel, Ranken).
func _cover_page(box: Control, cover: Control) -> void:
	box.get_parent().add_child(cover)
	cover.position = box.position - Vector2.ONE * BookStyle.PAGE_MARGIN + Vector2(0, 30)
	cover.size = box.size + Vector2.ONE * BookStyle.PAGE_MARGIN * 2 - Vector2(0, 30)


## Eine ausgerissene Seite: Nur ein schmaler Streifen am Falz ist übrig,
## darauf ein halbes Wort. Dahinter sieht man die nächste Seite (dunkler).
class TornStub:
	extends Control

	const STRIP := 34.0
	var fold_on_right := true
	var hint := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hint.hash()
		for y in int(size.y):
			var tear := STRIP + rng.randi_range(-3, 3)
			var x0 := 0.0 if fold_on_right else tear
			var width := size.x - tear
			draw_rect(Rect2(x0, y, width, 1), BookStyle.SHEET_SHADOW)
			# Ein heller Rissrand.
			var edge := size.x - tear - 1 if fold_on_right else tear
			draw_rect(Rect2(edge, y, 1, 1), BookStyle.SHEET_SHADOW_DEEP)
		var text_x := size.x - STRIP + 4 if fold_on_right else 4.0
		draw_string(get_theme_default_font(), Vector2(text_x, 30), hint, HORIZONTAL_ALIGNMENT_LEFT, STRIP - 6, 16, BookStyle.INK_VESPERA)
