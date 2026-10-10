class_name SpreadOffering
extends GrimoireSpread

## Das Opfer am Lesepult: links die befallene Seite, rechts die verlangten
## Gaben. Man legt sie aus dem Inventar in die Felder; fehlt etwas, steht dort
## genau, was. Man kann nicht scheitern. Ist alles da (und stimmt der Mond),
## welken die Ranken und Vesperas Tinte kehrt zurück.
## Design: docs/design/grimoire.md, Abschnitt 2 (Opfer am Lesepult).

const KIND_KEYS := {
	PageData.Kind.RECIPE: "BOOK_PAGE_KIND_RECIPE",
	PageData.Kind.JOURNAL: "BOOK_PAGE_KIND_JOURNAL",
	PageData.Kind.DIGITALIS: "BOOK_PAGE_KIND_DIGITALIS",
	PageData.Kind.HINT: "BOOK_PAGE_KIND_HINT",
}

var page_id := ""
# Item-ID -> Anzahl, die schon aus dem Inventar in die Felder gelegt wurde.
var _given: Dictionary = {}


func build(left: Control, right: Control) -> void:
	var pending := Grimoire.blighted_pages()
	if not pending.has(page_id):
		page_id = pending[0] if not pending.is_empty() else ""
	if page_id == "":
		left.add_child(BookStyle.label("BOOK_NOTHING_TO_RESTORE", BookStyle.INK_FAINT, text_width))
		return
	var page := PageData.from_id(page_id)
	_build_page(left, page, pending)
	_build_offering(right, page)


func _build_page(page_box: Control, page: PageData, pending: Array[String]) -> void:
	page_box.add_child(BookStyle.heading(KIND_KEYS[page.kind], BookStyle.INK_VESPERA_TITLE, text_width))
	page_box.add_child(BookStyle.label("BOOK_PAGE_BLIGHTED", BookStyle.INK_FAINT, text_width))
	# Mehrere befallene Seiten: zwischen ihnen wählen.
	if pending.size() > 1:
		for other in pending:
			var other_page := PageData.from_id(other)
			var button := BookStyle.text_button(KIND_KEYS[other_page.kind],
					BookStyle.INK if other == page_id else BookStyle.INK_FAINT)
			button.pressed.connect(func() -> void:
				on_close()
				page_id = other
				book.refresh())
			page_box.add_child(button)
	var vines := SpreadBlank.Vines.new()
	vines.seed_value = page_id.hash()
	page_box.get_parent().add_child(vines)
	vines.position = page_box.position + Vector2(0, 40)
	vines.size = page_box.size - Vector2(0, 40)


func _build_offering(page_box: Control, page: PageData) -> void:
	page_box.add_child(BookStyle.heading("BOOK_OFFERING", BookStyle.INK_VESPERA_TITLE, text_width))
	page_box.add_child(BookStyle.label("BOOK_OFFERING_HINT", BookStyle.INK_FAINT, text_width))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	for item_id: String in page.offering:
		var slot := OfferSlot.new()
		slot.item_id = item_id
		slot.need = page.offering[item_id]
		slot.given = int(_given.get(item_id, 0))
		slot.offering = self
		slots.add_child(slot)
	page_box.add_child(slots)

	if page.moon_condition >= 0:
		var moon_name := Moon.phase_name(page.moon_condition)
		page_box.add_child(BookStyle.label(tr("BOOK_MOON_CONDITION") % moon_name,
				BookStyle.INK if Grimoire.is_moon_right(page) else BookStyle.MISSING, text_width))
	var missing := _missing(page)
	if not missing.is_empty():
		page_box.add_child(BookStyle.label(tr("BOOK_MISSING") % ", ".join(missing), BookStyle.MISSING, text_width))
	var offer := BookStyle.button("BOOK_OFFER")
	offer.disabled = not missing.is_empty() or not Grimoire.is_moon_right(page)
	offer.pressed.connect(_offer)
	page_box.add_child(offer)

	# Das Inventar zum Hineinziehen, wie im Brau-Fenster.
	var grid := InventoryGrid.new()
	grid.first_slot = 0
	grid.slot_count = Inventory.SIZE
	grid.slot_size = 20
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 1)
	page_box.add_child(grid)


## Namen der Gaben, die noch fehlen (auch im Inventar nicht genug).
func _missing(page: PageData) -> Array[String]:
	var result: Array[String] = []
	for item_id: String in page.offering:
		if int(_given.get(item_id, 0)) < page.offering[item_id]:
			result.append(Inventory.display_name_for(item_id))
	return result


## Aus einem Inventar-Platz so viele nehmen, wie noch fehlen.
func give(item_id: String, inventory_slot: int) -> void:
	var page := PageData.from_id(page_id)
	var still_needed: int = page.offering[item_id] - int(_given.get(item_id, 0))
	var amount := mini(still_needed, Inventory.count_in_slot(inventory_slot))
	if amount > 0 and Inventory.remove_from_slot(inventory_slot, amount):
		_given[item_id] = int(_given.get(item_id, 0)) + amount
		book.refresh()


func take_back(item_id: String) -> void:
	var amount := int(_given.get(item_id, 0))
	if amount > 0 and Inventory.add(item_id, amount):
		_given.erase(item_id)
		book.refresh()


## Nicht geopferte Gaben wandern zurück. Passt etwas nicht mehr hinein,
## bleibt es hier liegen, bis wieder Platz ist.
func on_close() -> void:
	for item_id: String in _given.keys():
		if Inventory.add(item_id, _given[item_id]):
			_given.erase(item_id)
	if not _given.is_empty():
		Messages.deny(tr("MSG_BAG_FULL"))


func _offer() -> void:
	_given.clear()
	var restored := page_id
	Grimoire.restore_page(restored)
	Messages.post(tr("MSG_PAGE_RESTORED"))
	# Gleich zeigen, was auf der Seite steht.
	var page := PageData.from_id(restored)
	if Grimoire.blighted_pages().is_empty():
		book.go_to("journal" if page.kind == PageData.Kind.JOURNAL else "recipes")
	else:
		book.refresh()
