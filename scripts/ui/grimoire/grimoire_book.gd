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

var _frame: Control
var _pages: Control


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
	_build_tabs()
	Grimoire.changed.connect(refresh)


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
	show()
	_rebuild()


## Am Lesepult mit befallenen Seiten: gleich die Opfer-Ansicht zeigen.
func open_offering() -> void:
	open("", false, true)
	_special = SpreadOffering.new(self, null)
	_rebuild()


func close() -> void:
	_current_spread().on_close()
	hide()
	if not _paused_before:
		get_tree().paused = false
	if _hid_hotbar:
		get_tree().call_group("hotbar", "show")
	get_tree().call_group("clock", "show")


func go_to(chapter_id: String) -> void:
	_leave_special()
	_index = _find(chapter_id)
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
		refresh()


## Zum nächsten offenen Kapitel; versiegelte werden übersprungen.
func _change_chapter(direction: int) -> void:
	_leave_special()
	var i := _index
	for step in _chapters.size():
		i = wrapi(i + direction, 0, _chapters.size())
		if Grimoire.is_unlocked(_chapters[i]):
			_index = i
			refresh()
			return


func _rebuild() -> void:
	_refresh_queued = false
	for child in _pages.get_children():
		child.queue_free()
	var left := _page_box(BookStyle.LEFT_PAGE)
	var right := _page_box(BookStyle.RIGHT_PAGE)
	_current_spread().build(left, right)
	_update_tabs()


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
	var y := BookStyle.COVER.position.y + 10.0
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
		tab.queue_redraw()


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


## Einband, Seitenstapel, Papier und Falz. Platzhalter-Zeichnung, bis es die
## Buchgrafiken gibt (docs/design/grimoire.md, Abschnitt 6).
class BookFrame:
	extends Control

	func _draw() -> void:
		var cover := BookStyle.COVER
		draw_rect(cover, BookStyle.BLACK)
		draw_rect(cover.grow(-1), BookStyle.BORDEAUX_DARK)
		draw_rect(cover.grow(-3), BookStyle.BORDEAUX)
		draw_rect(cover.grow(-5), BookStyle.BORDEAUX_DARK)
		_gold_corners(cover.grow(-2))
		for page: Rect2 in [BookStyle.LEFT_PAGE, BookStyle.RIGHT_PAGE]:
			# Seitenkanten als Stapel unten und außen.
			for i in range(3, 0, -1):
				var stack: Rect2 = page.grow_individual(i if page == BookStyle.LEFT_PAGE else 0, 0,
						i if page == BookStyle.RIGHT_PAGE else 0, i)
				draw_rect(stack, BookStyle.SHEET_SHADOW_DEEP if i % 2 else BookStyle.SHEET_SHADOW)
			draw_rect(page, BookStyle.BONE)
		# Zum Falz hin wird das Papier dunkler (in Stufen, keine Verläufe).
		var left := BookStyle.LEFT_PAGE
		var right := BookStyle.RIGHT_PAGE
		draw_rect(Rect2(left.end.x - 8, left.position.y, 8, left.size.y), BookStyle.SHEET_SHADOW)
		draw_rect(Rect2(left.end.x - 3, left.position.y, 3, left.size.y), BookStyle.SHEET_SHADOW_DEEP)
		draw_rect(Rect2(right.position.x, right.position.y, 8, right.size.y), BookStyle.SHEET_SHADOW)
		draw_rect(Rect2(right.position.x, right.position.y, 3, right.size.y), BookStyle.SHEET_SHADOW_DEEP)
		draw_rect(BookStyle.FOLD, BookStyle.BORDEAUX_DEEP)

	func _gold_corners(rect: Rect2) -> void:
		var length := 10.0
		for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
			var dx := 1.0 if corner.x == rect.position.x else -1.0
			var dy := 1.0 if corner.y == rect.position.y else -1.0
			var start := corner - Vector2(0 if dx > 0 else 2, 0 if dy > 0 else 2)
			draw_rect(Rect2(start.x if dx > 0 else start.x - length + 2, start.y, length, 2), BookStyle.GOLD)
			draw_rect(Rect2(start.x, start.y if dy > 0 else start.y - length + 2, 2, length), BookStyle.GOLD)
