class_name GrimoireBook
extends Control

## Vesperas Grimoire als aufgeschlagenes Buch (Taste B, sobald gefunden).
## Jede Ansicht ist eine Doppelseite; welches Kapitel welche Vorlage benutzt,
## steht in den Kapitel-Dateien (data/grimoire/chapters/). Solange das Buch
## offen ist, ist das Spiel pausiert. Design: docs/design/grimoire.md.
##
## Bedienung: B/Esc schließen, A/D oder ←/→ blättern, W/S oder ↑/↓ Kapitel,
## Maus auf Lesezeichen und Einträge, Mausrad blättert.

# Hintergrund zu 70 % abgedunkelt, damit das Buch im Vordergrund steht.
const DIM := Color(0.054902, 0.0392157, 0.0784314, 0.7)

## Am Kessel geöffnet? Dann zeigt Recipes "Brew this".
var opened_from_cauldron := false
## Am Lesepult geöffnet? Dann lassen sich Pfade wechseln.
var opened_at_lectern := false

var _chapters: Array[ChapterData] = []
var _index := 0
# Kapitel-ID -> Doppelseite. Bleibt bestehen, damit z. B. der gewählte
# Eintrag erhalten bleibt, wenn man das Kapitel wechselt und zurückkommt.
var _spreads: Dictionary = {}
var _tabs: Array[BookTab] = []
var _paused_before := false
var _hid_hotbar := false
var _refresh_queued := false
# Eine Ansicht ohne eigenes Lesezeichen (das Opfer am Lesepult). Solange sie
# gesetzt ist, zeigt das Buch sie statt des Kapitels.
var _special: GrimoireSpread
# Richtung des nächsten Umblätterns (-1 zurück, 1 vor, 0 = nur neu aufbauen).
var _pending_flip := 0

var _frame: BookFrame
var _pages: Control
var _turn: PageTurn
var _hint: Label


func _ready() -> void:
	hide()
	add_to_group("grimoire_book")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_chapters = ChapterData.all()

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_frame = BookFrame.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_pages = Control.new()
	_pages.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pages)
	_turn = PageTurn.new()
	_turn.set_anchors_preset(Control.PRESET_FULL_RECT)
	_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_turn)
	_hint = Label.new()
	_hint.position = Vector2(BookStyle.COVER.position.x, BookStyle.HINT_Y)
	_hint.size = Vector2(BookStyle.COVER.size.x, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", BookStyle.LABEL_DIM)
	add_child(_hint)
	_build_tabs()
	Grimoire.changed.connect(refresh)
	# Das kleine Buch im HUD hängt neben dem Buch in der UI, damit es sichtbar
	# bleibt, während das Buch zu ist.
	var indicator := BookIndicator.new()
	indicator.book = self
	get_parent().add_child.call_deferred(indicator)


## chapter_id leer: dort öffnen, wo es Neues gibt, sonst auf der zuletzt
## gelesenen Seite.
func open(chapter_id: String = "", from_cauldron: bool = false, at_lectern: bool = false) -> void:
	if not Grimoire.has_book:
		return
	opened_from_cauldron = from_cauldron
	opened_at_lectern = at_lectern
	_special = null
	if chapter_id != "":
		_index = _find(chapter_id)
	else:
		var with_news := _first_with_news()
		if with_news >= 0:
			_index = with_news
	if not Grimoire.is_unlocked(_chapters[_index]):
		_index = 0
	_paused_before = get_tree().paused
	get_tree().paused = true
	# Die Hotbar ragt sonst unten ins Buch. Am Kessel ist sie schon weg.
	_hid_hotbar = not from_cauldron
	if _hid_hotbar:
		get_tree().call_group("hotbar", "hide")
	# Uhr und Mondphase lägen oben rechts unter den Lesezeichen.
	get_tree().call_group("clock", "hide")
	# Am Kessel liegt das Brau-Fenster darunter und schimmert sonst durch.
	if from_cauldron:
		get_tree().call_group("brew_window", "hide")
	_hint.text = "BOOK_HINT_LECTERN" if at_lectern else "BOOK_HINT"
	_frame.queue_redraw()
	show()
	Sfx.play("ui/open")
	_rebuild()


## Am Lesepult mit befallenen Seiten: gleich die Opfer-Ansicht zeigen.
func open_offering() -> void:
	open("", false, true)
	_special = SpreadOffering.new(self, null)
	_rebuild()


func close() -> void:
	_current_spread().on_close()
	Sfx.play("ui/close")
	hide()
	if not _paused_before:
		get_tree().paused = false
	if _hid_hotbar:
		get_tree().call_group("hotbar", "show")
	else:
		get_tree().call_group("brew_window", "show")
	# Die Uhr bleibt aus, solange am Kessel das Brau-Fenster offen ist.
	if not opened_from_cauldron:
		get_tree().call_group("clock", "show")


func go_to(chapter_id: String) -> void:
	_leave_special()
	var target := _find(chapter_id)
	_pending_flip = signi(target - _index)
	_index = target
	refresh()


## Zum Herbarium-Eintrag einer Zutat (Klick im Rezept).
func show_item_entry(item_id: String) -> void:
	go_to("herbarium")
	var spread := _spread_for(_chapters[_index])
	if spread is SpreadHerbarium:
		(spread as SpreadHerbarium).select_item(item_id)


## Baut die Doppelseite neu auf, am Ende des Frames: So darf ein Knopf auf
## der Seite das auslösen, ohne sich selbst mitten im Klick zu löschen.
func refresh() -> void:
	if visible and not _refresh_queued:
		_refresh_queued = true
		_rebuild.call_deferred()


## Gibt es irgendwo im Buch etwas Neues? (Für das kleine Buch im HUD.)
func any_news() -> bool:
	return _first_with_news() >= 0


## "Brew this": Zutaten aus dem Inventar in den Kessel legen.
func brew_this(recipe: RecipeData) -> void:
	close()
	get_tree().call_group("brew_window", "fill_with", recipe.ingredients)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		if event.is_action_pressed("book") and not get_tree().paused:
			open()
			get_viewport().set_input_as_handled()
		return
	var handled := true
	if event.is_action_pressed("book") or event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_flip(-1)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_flip(1)
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_change_chapter(-1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_change_chapter(1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_flip(-1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_flip(1)
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


## Erst innerhalb des Kapitels, am Ende ins nächste offene Kapitel.
func _flip(direction: int) -> void:
	if _special:
		return
	if not _spread_for(_chapters[_index]).flip(direction):
		_change_chapter(direction)
	else:
		_pending_flip = direction
		refresh()


## Zum nächsten offenen Kapitel; versiegelte werden übersprungen.
func _change_chapter(direction: int) -> void:
	_leave_special()
	var i := _index
	for step in _chapters.size():
		i = wrapi(i + direction, 0, _chapters.size())
		if Grimoire.is_unlocked(_chapters[i]):
			_index = i
			_pending_flip = direction
			refresh()
			return


func _rebuild() -> void:
	_refresh_queued = false
	for child in _pages.get_children():
		child.queue_free()
	var left := _page_box(BookStyle.LEFT_PAGE)
	var right := _page_box(BookStyle.RIGHT_PAGE)
	var spread := _current_spread()
	spread.build(left, right)
	_add_page_numbers(spread)
	_update_tabs()
	if _pending_flip != 0:
		_turn.play(_pending_flip)
		Sfx.play("ui/page_turn")
		_pending_flip = 0


func _current_spread() -> GrimoireSpread:
	return _special if _special else _spread_for(_chapters[_index])


func _leave_special() -> void:
	if _special:
		_special.on_close()
		_special = null


func _page_box(page: Rect2) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = page.position + Vector2.ONE * BookStyle.PAGE_MARGIN
	box.size = page.size - Vector2.ONE * BookStyle.PAGE_MARGIN * 2
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pages.add_child(box)
	return box


## Seitenzahlen unten in der Mitte jeder Seite, z. B. "· 7 ·".
func _add_page_numbers(spread: GrimoireSpread) -> void:
	var first := _index * 2 + 1 + spread.page_offset()
	for i in 2:
		var page: Rect2 = BookStyle.LEFT_PAGE if i == 0 else BookStyle.RIGHT_PAGE
		var number := BookStyle.label("· %d ·" % (first + i), BookStyle.INK_FAINT)
		number.position = Vector2(page.position.x, page.end.y - 16)
		number.size = Vector2(page.size.x, 14)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pages.add_child(number)


func _spread_for(chapter: ChapterData) -> GrimoireSpread:
	var spread: GrimoireSpread = _spreads.get(chapter.id)
	# Neu bauen, wenn sich das Kapitel inzwischen geöffnet hat.
	var sealed := spread is SpreadBlank and (spread as SpreadBlank).sealed
	if spread == null or sealed == Grimoire.is_unlocked(chapter):
		spread = _make_spread(chapter)
		_spreads[chapter.id] = spread
	return spread


func _make_spread(chapter: ChapterData) -> GrimoireSpread:
	if not Grimoire.is_unlocked(chapter):
		var sealed := SpreadBlank.new(self, chapter)
		sealed.sealed = true
		return sealed
	match chapter.id:
		"cover":
			return SpreadCover.new(self, chapter)
		"recipes":
			return SpreadRecipes.new(self, chapter)
		"journal":
			return SpreadJournal.new(self, chapter)
		"herbarium", "bestiary":
			return SpreadHerbarium.new(self, chapter)
		"digitalis", "people":
			return SpreadSilhouettes.new(self, chapter)
	if chapter.template == ChapterData.Template.DISCIPLINE and DisciplineData.from_id(chapter.id):
		return SpreadDiscipline.new(self, chapter)
	return SpreadBlank.new(self, chapter)


# --- Lesezeichen ---------------------------------------------------------------

func _build_tabs() -> void:
	var y := BookStyle.COVER.position.y + 8.0
	var last_group := -1
	for chapter in _chapters:
		if last_group != -1 and chapter.group != last_group:
			y += BookStyle.TAB_GROUP_GAP
		last_group = chapter.group
		var tab := BookTab.new(chapter)
		tab.position = Vector2(BookStyle.TAB_X, y)
		# Versiegelte Kapitel kann man aufschlagen, aber nicht lesen.
		tab.chosen.connect(func(c: ChapterData) -> void: go_to(c.id))
		add_child(tab)
		_tabs.append(tab)
		y += BookStyle.TAB_HEIGHT + BookStyle.TAB_GAP


func _update_tabs() -> void:
	for i in _tabs.size():
		var tab := _tabs[i]
		tab.active = i == _index and _special == null
		tab.locked = not Grimoire.is_unlocked(tab.chapter)
		tab.has_new = not tab.locked and _spread_for(tab.chapter).has_new()
		tab.refresh()


func _find(chapter_id: String) -> int:
	for i in _chapters.size():
		if _chapters[i].id == chapter_id:
			return i
	return 0


func _first_with_news() -> int:
	for i in _chapters.size():
		if Grimoire.is_unlocked(_chapters[i]) and _spread_for(_chapters[i]).has_new():
			return i
	return -1


## Einband, Buchblock, gealtertes Papier, Falz und Lesebändchen.
## Platzhalter-Zeichnung, bis es die Buchgrafiken gibt (grimoire.md, Abschnitt 6).
class BookFrame:
	extends Control

	const COVER_LIGHT := Color("#962C48")

	func _draw() -> void:
		var cover := BookStyle.COVER
		draw_rect(cover, BookStyle.BLACK)
		draw_rect(cover.grow(-1), BookStyle.BORDEAUX_DARK)
		draw_rect(cover.grow(-3), BookStyle.BORDEAUX)
		draw_rect(cover.grow(-5), BookStyle.BORDEAUX_DARK)
		# Licht von oben links: helle Kante oben und links am Einband.
		draw_rect(Rect2(cover.position + Vector2(3, 3), Vector2(cover.size.x - 6, 1)), COVER_LIGHT)
		draw_rect(Rect2(cover.position + Vector2(3, 3), Vector2(1, cover.size.y - 6)), COVER_LIGHT)
		_gold_corners(cover.grow(-2))
		# Der Buchblock wird mit den gefundenen Seiten etwas dicker.
		var layers := 2 + mini(4, Grimoire.found_page_count() / 2)
		for page: Rect2 in [BookStyle.LEFT_PAGE, BookStyle.RIGHT_PAGE]:
			var is_left := page == BookStyle.LEFT_PAGE
			for i in range(layers, 0, -1):
				var stack: Rect2 = page.grow_individual(i if is_left else 0, 0, 0 if is_left else i, i)
				draw_rect(stack, BookStyle.SHEET_SHADOW_DEEP if i % 2 else BookStyle.SHEET_SHADOW)
			draw_rect(page, BookStyle.BONE)
			_age(page, 17 if is_left else 31)
		# Zum Falz hin wird das Papier dunkler (in Stufen, keine Verläufe).
		var left := BookStyle.LEFT_PAGE
		var right := BookStyle.RIGHT_PAGE
		draw_rect(Rect2(left.end.x - 8, left.position.y, 8, left.size.y), BookStyle.SHEET_SHADOW)
		draw_rect(Rect2(left.end.x - 3, left.position.y, 3, left.size.y), BookStyle.SHEET_SHADOW_DEEP)
		draw_rect(Rect2(right.position.x, right.position.y, 8, right.size.y), BookStyle.SHEET_SHADOW)
		draw_rect(Rect2(right.position.x, right.position.y, 3, right.size.y), BookStyle.SHEET_SHADOW_DEEP)
		draw_rect(BookStyle.FOLD, BookStyle.BORDEAUX_DEEP)
		# Fingerhut-Schmuck in den äußeren unteren Ecken.
		BookStyle.draw_foxglove(self, Vector2(left.position.x + 5, left.end.y - 15), 0.8)
		BookStyle.draw_foxglove(self, Vector2(right.end.x - 12, right.end.y - 15), 0.8)
		_ribbon()

	## Gealtertes Papier: verstreute Flecken und abgegriffene Ecken. Immer
	## gleich (fester Zufall), damit nichts flackert.
	func _age(page: Rect2, seed_value: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var spot := Color(BookStyle.SHEET_SHADOW, 0.55)
		for i in 70:
			var p := Vector2(rng.randi_range(int(page.position.x) + 2, int(page.end.x) - 3),
					rng.randi_range(int(page.position.y) + 2, int(page.end.y) - 3))
			draw_rect(Rect2(p, Vector2.ONE * (2 if rng.randf() < 0.15 else 1)), spot)
		for corner: Vector2 in [page.position, Vector2(page.end.x - 1, page.position.y),
				Vector2(page.position.x, page.end.y - 1), page.end - Vector2.ONE]:
			var dx := 1.0 if corner.x == page.position.x else -1.0
			var dy := 1.0 if corner.y == page.position.y else -1.0
			for d in 3:
				draw_rect(Rect2(corner + Vector2(dx * d, 0), Vector2.ONE), BookStyle.SHEET_SHADOW)
				draw_rect(Rect2(corner + Vector2(0, dy * d), Vector2.ONE), BookStyle.SHEET_SHADOW)

	## Lesebändchen: schaut unten rechts aus dem Buch heraus (über die Seite
	## gelegt würde es den Text verdecken).
	func _ribbon() -> void:
		var x := BookStyle.RIGHT_PAGE.end.x - 44
		var top := BookStyle.RIGHT_PAGE.end.y - 3
		var bottom := BookStyle.COVER.end.y + 9
		draw_rect(Rect2(x, top, 5, bottom - top), BookStyle.BORDEAUX)
		draw_rect(Rect2(x, top, 1, bottom - top), COVER_LIGHT)
		draw_rect(Rect2(x + 4, top, 1, bottom - top), BookStyle.BORDEAUX_DEEP)
		# Schwalbenschwanz am Ende.
		draw_rect(Rect2(x, bottom, 2, 2), BookStyle.BORDEAUX)
		draw_rect(Rect2(x + 3, bottom, 2, 2), BookStyle.BORDEAUX)

	func _gold_corners(rect: Rect2) -> void:
		var length := 10.0
		for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
			var dx := 1.0 if corner.x == rect.position.x else -1.0
			var dy := 1.0 if corner.y == rect.position.y else -1.0
			var start := corner - Vector2(0 if dx > 0 else 2, 0 if dy > 0 else 2)
			draw_rect(Rect2(start.x if dx > 0 else start.x - length + 2, start.y, length, 2), BookStyle.GOLD)
			draw_rect(Rect2(start.x, start.y if dy > 0 else start.y - length + 2, 2, length), BookStyle.GOLD)


## Umblättern: Eine Seitenkante mit Schatten läuft über das Buch, darunter
## erscheint schon die neue Doppelseite. Kurz, damit es beim schnellen
## Blättern nicht stört. (Später durch 3–4 gezeichnete Frames ersetzbar.)
class PageTurn:
	extends Control

	const DURATION := 0.18
	var _progress := 1.0
	var _direction := 1

	func play(direction: int) -> void:
		_direction = direction
		_progress = 0.0
		var tween := create_tween()
		tween.tween_method(_set_progress, 0.0, 1.0, DURATION)

	func _set_progress(value: float) -> void:
		_progress = value
		queue_redraw()

	func _draw() -> void:
		if _progress >= 1.0:
			return
		var left := BookStyle.LEFT_PAGE.position.x
		var right := BookStyle.RIGHT_PAGE.end.x
		# Vorwärts läuft die Kante von rechts nach links, zurück umgekehrt.
		var t := _progress if _direction > 0 else 1.0 - _progress
		var x := roundf(lerpf(right, left, t))
		var top := BookStyle.LEFT_PAGE.position.y - 2
		var height := BookStyle.LEFT_PAGE.size.y + 4
		draw_rect(Rect2(x - 6, top, 12, height), BookStyle.BONE)
		draw_rect(Rect2(x - 6, top, 1, height), BookStyle.SHEET_SHADOW_DEEP)
		draw_rect(Rect2(x + 6, top, 3, height), Color(BookStyle.AUBERGINE, 0.35))
