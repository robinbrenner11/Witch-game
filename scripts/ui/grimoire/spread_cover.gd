class_name SpreadCover
extends GrimoireSpread

## Innendeckel: links Vesperas Notiz mit den ersten Zielen (durchgestrichen,
## sobald erledigt). Rechts die Übersicht der neuen Besitzerin: die Hand, deren
## Fingerspitzen mit der Hexenstärke schwarz werden (Summe aller
## Disziplin-Stufen), darunter alle Disziplinen und wie viel vom Buch schon
## gefunden ist. Design: docs/design/grimoire.md, Abschnitte 1 und 3.

const NOTE_KEY := "BOOK_NOTE_START"
const GOAL_KEYS := {
	"plant": "GOAL_PLANT",
	"brew": "GOAL_BREW",
	"sleep": "GOAL_SLEEP",
	"wake": "GOAL_WAKE",
}
# Ab so viel Hexenstärke wird die nächste der 5 Stufen der Hand erreicht.
const HAND_STEPS: Array[int] = [0, 5, 12, 20, 30]


func build(left: Control, right: Control) -> void:
	_build_note(left)
	_build_overview(right)


func _build_note(page: Control) -> void:
	var note := RichTextLabel.new()
	note.bbcode_enabled = true
	note.fit_content = true
	note.scroll_active = false
	note.custom_minimum_size.x = text_width
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_theme_color_override("default_color", BookStyle.INK_VESPERA)
	# Zusammengesetzter Text, deshalb tr() von Hand: Godot übersetzt nur
	# Texte automatisch, die genau ein Schlüssel sind.
	var text := tr(NOTE_KEY)
	for goal in Grimoire.GOALS:
		var line := tr(GOAL_KEYS[goal])
		if Grimoire.is_goal_done(goal):
			line = "[s][color=#%s]%s[/color][/s]" % [BookStyle.INK_FAINT.to_html(false), line]
		text += "\n· " + line
	note.text = text
	page.add_child(note)
	var signature := BookStyle.label("BOOK_SIGNATURE", BookStyle.INK_VESPERA_TITLE, text_width)
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page.add_child(signature)
	# Darunter antwortet die neue Besitzerin, in ihrer eigenen Tinte.
	page.add_child(BookStyle.label("COVER_OWNER", BookStyle.INK_PLAYER, text_width))


func _build_overview(page: Control) -> void:
	page.add_child(BookStyle.heading("COVER_STRENGTH", BookStyle.INK_VESPERA_TITLE, text_width))
	var strength := Grimoire.witch_strength()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var hand := WitchHand.new()
	hand.stage = _hand_stage(strength)
	top.add_child(hand)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	var number := BookStyle.label(str(strength), BookStyle.GOLD_DARK)
	number.add_theme_font_size_override("font_size", 32)
	info.add_child(number)
	info.add_child(BookStyle.label("BOOK_STRENGTH_TEXT", BookStyle.INK_FAINT, text_width - 60))
	top.add_child(info)
	page.add_child(top)
	page.add_child(BookStyle.rule_plain(text_width))

	# Alle Disziplinen mit ihrer Farbe und Stufe.
	for chapter in ChapterData.all():
		var discipline := DisciplineData.from_id(chapter.id)
		if discipline == null:
			continue
		page.add_child(_overview_row(chapter.title_key, tr("BOOK_LEVEL") % Grimoire.level(discipline.id), chapter.tab_color))
	page.add_child(BookStyle.rule_plain(text_width))
	var pages := PageData.all().size()
	var found := 0
	for page_id: String in PageData.all():
		if Grimoire.is_page_found(page_id):
			found += 1
	var recipes := RecipeData.all()
	var known := recipes.filter(func(r: RecipeData) -> bool: return Grimoire.knows_recipe(r)).size()
	var entries := EntryData.in_chapter("herbarium")
	var discovered := entries.filter(func(e: EntryData) -> bool: return Grimoire.is_discovered(e)).size()
	page.add_child(_overview_row("BOOK_OVERVIEW_PAGES", "%d/%d" % [found, pages], Color.TRANSPARENT))
	page.add_child(_overview_row("BOOK_OVERVIEW_RECIPES", "%d/%d" % [known, recipes.size()], Color.TRANSPARENT))
	page.add_child(_overview_row("BOOK_OVERVIEW_HERBARIUM", "%d/%d" % [discovered, entries.size()], Color.TRANSPARENT))


## Name links, Wert rechts, davor optional ein kleines Farbfeld.
func _overview_row(name_key: String, value: String, swatch: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.x = text_width
	if swatch.a > 0.0:
		var box := ColorRect.new()
		box.color = swatch
		box.custom_minimum_size = Vector2(6, 6)
		box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(box)
	row.add_child(BookStyle.label(name_key, BookStyle.INK))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(BookStyle.label(value, BookStyle.GOLD_DARK))
	return row


func _hand_stage(strength: int) -> int:
	var stage := 0
	for i in HAND_STEPS.size():
		if strength >= HAND_STEPS[i]:
			stage = i
	return stage


## Die Hand der Hexe als Pixelzeichnung (Platzhalter bis zur Grafik).
## Licht von oben links. Die Fingerspitzen werden in 5 Stufen schwarz,
## bei Stufe 4 sind die Finger fast ganz dunkel wie bei Vespera.
class WitchHand:
	extends Control

	const OUTLINE := Color("#2B1633")
	const SKIN_DARK := Color("#4A2B27")
	const SKIN := Color("#6B3F33")
	const SKIN_LIGHT := Color("#8A5240")
	const NAIL := Color("#0E0A14")
	const NAIL_EDGE := Color("#2B1633")
	# x, Länge der vier Finger (von links: Zeigefinger bis kleiner Finger).
	const FINGERS := [[6, 26], [12, 30], [18, 28], [24, 22]]
	const FINGER_WIDTH := 5
	const PALM_TOP := 34

	var stage := 0

	func _ready() -> void:
		custom_minimum_size = Vector2(44, 70)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Handfläche mit abgerundeten Ecken.
		_blob(Rect2(5, PALM_TOP, 25, 22))
		for finger in FINGERS:
			var x: int = finger[0]
			var length: int = finger[1]
			var rect := Rect2(x, PALM_TOP - length + 4, FINGER_WIDTH, length)
			_blob(rect)
			# Schwarze Spitzen, je nach Hexenstärke länger.
			var tip := 3 + stage * 4
			draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, FINGER_WIDTH - 2, tip), NAIL)
			draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1 + tip, FINGER_WIDTH - 2, 1), NAIL_EDGE)
		# Daumen schräg nach links.
		for i in 4:
			_blob(Rect2(1 + i, PALM_TOP + 12 - i * 3, 7, 6))
		draw_rect(Rect2(2, PALM_TOP + 4, 5, 3 + stage), NAIL)
		# Goldener Armreif und Handgelenk.
		_blob(Rect2(9, PALM_TOP + 21, 17, 12))
		draw_rect(Rect2(8, PALM_TOP + 23, 19, 3), BookStyle.GOLD)
		draw_rect(Rect2(8, PALM_TOP + 23, 19, 1), Color("#F4CC78"))
		draw_rect(Rect2(8, PALM_TOP + 25, 19, 1), BookStyle.GOLD_DARK)

	## Eine gefüllte Form mit Kontur, Licht links oben, Schatten rechts.
	func _blob(rect: Rect2) -> void:
		draw_rect(Rect2(rect.position.x + 1, rect.position.y, rect.size.x - 2, rect.size.y), OUTLINE)
		draw_rect(Rect2(rect.position.x, rect.position.y + 1, rect.size.x, rect.size.y - 2), OUTLINE)
		var inner := rect.grow(-1)
		draw_rect(inner, SKIN)
		draw_rect(Rect2(inner.position, Vector2(1, inner.size.y)), SKIN_LIGHT)
		draw_rect(Rect2(inner.end.x - 1, inner.position.y, 1, inner.size.y), SKIN_DARK)
