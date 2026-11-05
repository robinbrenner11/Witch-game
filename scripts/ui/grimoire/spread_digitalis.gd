class_name SpreadDigitalis
extends GrimoireSpread

## Kapitel Digitalis: links die Formen (bekannte mit Bild, die anderen als
## Silhouette), rechts die gewählte Form mit ihren Angriffen, ihrem Nutzen
## draußen, der Upgrade-Stufe als Kerben und dem, was Gnarl für die nächste
## Stufe braucht. Design: docs/design/grimoire.md, Abschnitt Digitalis.

# Alle Formen laut Design, in dieser Reihenfolge. Was es noch nicht als
# Datei gibt (Dornenpeitsche, Wurzelhammer), bleibt eine Silhouette.
const FORMS := ["staff", "sickle", "thornwhip", "rootmaul"]
const GNARL := "gnarl"
# Ab diesem Flag steht Gnarl in seiner Werkstatt und nennt seine Preise.
const GNARL_IN_WORKSHOP := "gnarl_moved"

var _selected := ""


func build(left: Control, right: Control) -> void:
	var known := Grimoire.known_forms()
	if _selected == "" and not known.is_empty():
		_selected = known[0]
	add_title(left)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	for form_id in FORMS:
		grid.add_child(_slot(form_id, known.has(form_id)))
	left.add_child(grid)
	if known.has(_selected):
		_build_form(right, _selected)
	else:
		right.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
		right.add_child(BookStyle.label("DIGITALIS_GNARL_HINT", BookStyle.INK_FAINT, text_width))


## Höchste Stufe, für die es eine Datei gibt (1 = keine Upgrades).
static func max_level(form_id: String) -> int:
	var level := 1
	while ResourceLoader.exists(DigitalisForm.UPGRADE_DIRECTORY % [form_id, level + 1]):
		level += 1
	return level


## Gnarls Angebot für die nächste Stufe dieser Form, oder null.
static func next_offer(form_id: String) -> TradeOffer:
	var next := Grimoire.upgrade_level(form_id) + 1
	for offer in TradeOffer.all_for(GNARL):
		if offer.reward and offer.reward.type == RewardData.Type.UPGRADE \
				and offer.reward.target_id == form_id and offer.reward.value == next:
			return offer
	return null


func _slot(form_id: String, known: bool) -> BookSlot:
	var slot := BookSlot.new()
	slot.data = form_id
	slot.selected = form_id == _selected
	var form := DigitalisForm.from_id(form_id)
	if known and form:
		slot.state = BookSlot.State.KNOWN
		slot.icon = form.icon
		# Goldenes Quadrat: ganz ausgebaut.
		slot.marked = Grimoire.upgrade_level(form_id) >= max_level(form_id) and max_level(form_id) > 1
	else:
		slot.state = BookSlot.State.UNKNOWN
	slot.chosen.connect(func(s: BookSlot) -> void:
		_selected = s.data
		book.refresh())
	return slot


func _build_form(page: Control, form_id: String) -> void:
	var key := "DIGITALIS_" + form_id.to_upper()
	var level := Grimoire.upgrade_level(form_id)
	var top := max_level(form_id)
	page.add_child(BookStyle.heading(key, BookStyle.INK_VESPERA_TITLE, text_width))
	var row := HBoxContainer.new()
	row.add_child(BookStyle.icon(DigitalisForm.from_id(form_id).icon))
	row.add_child(BookStyle.label(tr("BOOK_LEVEL") % level, BookStyle.GOLD_DARK))
	var notches := Notches.new()
	notches.total = top
	notches.filled = level
	row.add_child(notches)
	page.add_child(row)
	page.add_child(BookStyle.label(tr("DIGITALIS_LIGHT") % tr(key + "_LIGHT"), BookStyle.INK, text_width))
	page.add_child(BookStyle.label(tr("DIGITALIS_HEAVY") % tr(key + "_HEAVY"), BookStyle.INK, text_width))
	page.add_child(BookStyle.label(tr("DIGITALIS_WORLD") % tr(key + "_WORLD"), BookStyle.INK, text_width))
	# Was die Upgrades gebracht haben, in der Tinte der Spielerin.
	for stage in range(2, level + 1):
		page.add_child(BookStyle.label("%s: %s" % [tr("UPGRADE_%s_%d" % [form_id.to_upper(), stage]),
				tr("%s_UPGRADE_%d" % [key, stage])], BookStyle.INK_PLAYER, text_width))
	page.add_child(BookStyle.rule(text_width))
	_build_next(page, form_id)


## Was Gnarl für die nächste Stufe braucht. Vor seinem Umzug nur ein Hinweis,
## damit man ihn selbst findet.
func _build_next(page: Control, form_id: String) -> void:
	var offer := next_offer(form_id)
	if offer == null:
		if Grimoire.upgrade_level(form_id) >= max_level(form_id) and max_level(form_id) > 1:
			page.add_child(BookStyle.label("DIGITALIS_FULLY_CARVED", BookStyle.GOLD_DARK, text_width))
		return
	if not WorldState.has_flag(GNARL_IN_WORKSHOP):
		page.add_child(BookStyle.label("DIGITALIS_GNARL_HINT", BookStyle.INK_FAINT, text_width))
		return
	page.add_child(BookStyle.label(tr("DIGITALIS_GNARL_NEEDS") % SpreadDiscipline.reward_text(offer.reward),
			BookStyle.INK, text_width))
	var wants := offer.all_wants()
	for item_id in wants:
		page.add_child(_material_row(item_id, Inventory.count(item_id), wants[item_id]))


func _material_row(item_id: String, have: int, need: int) -> Control:
	var row := HBoxContainer.new()
	row.add_child(BookStyle.icon(Inventory.icon_for(item_id)))
	row.add_child(BookStyle.label(tr("BOOK_NEED") % need, BookStyle.INK_FAINT))
	var name := BookStyle.text_button(Inventory.display_name_for(item_id), BookStyle.INK)
	name.tooltip_text = "BOOK_TO_HERBARIUM"
	name.pressed.connect(func() -> void: book.show_item_entry(item_id))
	row.add_child(name)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if have >= need:
		row.add_child(SpreadDiscipline.Check.new())
	else:
		row.add_child(BookStyle.label("BOOK_HAVE_MISSING", BookStyle.MISSING))
	row.custom_minimum_size.x = text_width
	return row


## Kerben wie in Holz geschnitzt: eine pro Stufe, erreichte in Gold.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)
class Notches:
	extends Control

	const NOTCH := Vector2(3, 9)
	const GAP := 3.0

	var total := 1
	var filled := 1

	func _ready() -> void:
		custom_minimum_size = Vector2(total * (NOTCH.x + GAP) + GAP, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in total:
			var rect := Rect2(Vector2(GAP + i * (NOTCH.x + GAP), (size.y - NOTCH.y) / 2.0), NOTCH)
			draw_rect(rect, BookStyle.GOLD if i < filled else BookStyle.SHEET_SHADOW_DEEP)
			draw_rect(rect, BookStyle.AUBERGINE, false, 1.0)
