class_name SpreadDigitalis
extends GrimoireSpread

## Kapitel Digitalis: links die Formen als Raster, rechts die gewählte Form
## mit Stufe (Kerben), was Links- und Rechtsklick tun, wofür sie draußen gut
## ist und was Gnarl für die nächste Stufe will. Formen, die die Hexe noch
## nicht kennt, sind Silhouetten mit Hinweis. Design: docs/design/grimoire.md,
## Abschnitt 1 (Digitalis).

# Alle Formen in Buch-Reihenfolge, auch die, die es noch nicht als Daten gibt.
const ALL_FORMS: Array[String] = ["staff", "sickle", "thornwhip", "rootmaul"]
const NOTCH := Vector2(6, 6)
# Tafel für die große Abbildung: so groß wie die breiteste (Sichel) und
# höchste (Stab) Abbildung plus Rand, damit sie beim Umschalten nicht springt.
const PLATE_SIZE := Vector2(106, 219)
const PLATE_PADDING := 4.0

var _selected := "staff"


func has_new() -> bool:
	for form_id in Grimoire.known_forms():
		if not Grimoire.is_seen(_seen_key(form_id)):
			return true
	return false


func build(left: Control, right: Control) -> void:
	add_title(left)
	# Links eine schmale Spalte mit den Formen, rechts daneben die gewählte
	# Form groß auf einer dunklen Tafel.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var column_width := text_width - PLATE_SIZE.x - 6
	column.custom_minimum_size.x = column_width
	row.add_child(column)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for form_id in ALL_FORMS:
		var known := Grimoire.known_forms().has(form_id)
		var form := DigitalisForm.from_id(form_id, Grimoire.upgrade_level(form_id))
		var slot := BookSlot.new()
		slot.data = form_id
		slot.state = BookSlot.State.KNOWN if known and form else BookSlot.State.UNKNOWN
		slot.icon = form.icon if known and form else null
		slot.selected = form_id == _selected
		slot.marked = known and Grimoire.upgrade_level(form_id) >= max_level(form_id) and max_level(form_id) > 1
		slot.is_new = known and not Grimoire.is_seen(_seen_key(form_id))
		slot.chosen.connect(func(s: BookSlot) -> void:
			_selected = s.data
			book.refresh())
		grid.add_child(slot)
	column.add_child(grid)
	column.add_child(BookStyle.label("BOOK_FORMS_HINT", BookStyle.INK_FAINT, column_width))
	var selected_form := DigitalisForm.from_id(_selected, Grimoire.upgrade_level(_selected))
	if Grimoire.known_forms().has(_selected) and selected_form and selected_form.book_image:
		row.add_child(Plate.new(selected_form.book_image))
	left.add_child(row)
	if Grimoire.known_forms().has(_selected):
		_build_detail(right, _selected)
		Grimoire.mark_seen(_seen_key(_selected))
	else:
		right.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
		right.add_child(BookStyle.label("DIGITALIS_GNARL_HINT", BookStyle.INK_FAINT, text_width))


## Höchste Stufe, die es als Datei gibt.
static func max_level(form_id: String) -> int:
	var top := 1
	while DigitalisForm.from_id(form_id, top + 1) != null and DigitalisForm.from_id(form_id, top + 1).level == top + 1:
		top += 1
	return top


func _build_detail(page: Control, form_id: String) -> void:
	var level := Grimoire.upgrade_level(form_id)
	var title := "DIGITALIS_" + form_id.to_upper() if level <= 1 else Grimoire.upgrade_key(form_id, level)
	page.add_child(BookStyle.heading(title, BookStyle.INK_VESPERA_TITLE, text_width))
	page.add_child(Notches.new(level, max_level(form_id)))
	var prefix := "DIGITALIS_" + form_id.to_upper()
	page.add_child(BookStyle.label(tr("BOOK_FORM_LIGHT") % tr(prefix + "_LIGHT"), BookStyle.INK, text_width))
	page.add_child(BookStyle.label(tr("BOOK_FORM_HEAVY") % tr(prefix + "_HEAVY"), BookStyle.INK, text_width))
	page.add_child(BookStyle.label(tr("BOOK_FORM_WORLD") % tr(prefix + "_WORLD"), BookStyle.INK, text_width))
	if level > 1:
		page.add_child(BookStyle.label(Grimoire.upgrade_key(form_id, level) + "_NOTE", BookStyle.INK_PLAYER, text_width))
	page.add_child(BookStyle.rule(text_width))
	var next := TradeOffer.for_upgrade(form_id, level + 1)
	if next == null:
		page.add_child(BookStyle.label("BOOK_FORM_MAX", BookStyle.INK_FAINT, text_width))
	elif WorldState.has_flag("met_gnarl"):
		page.add_child(BookStyle.label(tr("BOOK_FORM_NEXT") % [tr(Grimoire.upgrade_key(form_id, level + 1)), next.cost_text()], BookStyle.INK_PLAYER, text_width))
	else:
		page.add_child(BookStyle.label("DIGITALIS_GNARL_HINT", BookStyle.INK_FAINT, text_width))


func _seen_key(form_id: String) -> String:
	return "form/%s/%d" % [form_id, Grimoire.upgrade_level(form_id)]


## Stufe als Kerben: gefüllt bis zur aktuellen Stufe, danach leer.
class Notches:
	extends Control

	var level := 1
	var top := 1

	func _init(current: int, highest: int) -> void:
		level = current
		top = highest
		custom_minimum_size = Vector2(top * (NOTCH.x + 3), NOTCH.y + 4)

	func _draw() -> void:
		for i in top:
			var rect := Rect2(Vector2(i * (NOTCH.x + 3), 2), NOTCH)
			if i < level:
				draw_rect(rect, BookStyle.GOLD)
				draw_rect(Rect2(rect.position, Vector2(NOTCH.x, 2)), BookStyle.GOLD.lightened(0.3))
			draw_rect(rect, BookStyle.GOLD_DARK, false)


## Die große Abbildung einer Form auf einer dunklen Tafel mit Goldrand,
## wie ein eingeklebtes Bild. Auf dem hellen Papier ginge die helle Klinge
## der Sichel sonst unter; auf Dunkel leuchten Magenta und Gold.
class Plate:
	extends Control

	var _image: Texture2D

	func _init(image: Texture2D) -> void:
		_image = image
		custom_minimum_size = PLATE_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, PLATE_SIZE)
		draw_rect(rect, BookStyle.AUBERGINE)
		BookStyle.draw_frame(self, rect, BookStyle.GOLD_DARK)
		BookStyle.draw_frame(self, rect.grow(-2), Color(BookStyle.GOLD_DARK, 0.4))
		# Unten mittig, auf ganze Pixel gerundet.
		var at := Vector2(roundf((PLATE_SIZE.x - _image.get_width()) / 2.0),
				PLATE_SIZE.y - PLATE_PADDING - _image.get_height())
		draw_texture(_image, at)
