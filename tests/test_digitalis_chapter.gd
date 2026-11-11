## Digitalis-Kapitel im Grimoire: Formen, Upgrade-Stufe als Kerben und was
## Gnarl für die nächste Stufe braucht.
extends TestCase

const CHAPTER := preload("res://data/grimoire/chapters/digitalis.tres")


func before_each() -> void:
	WorldState.reset()
	Inventory.reset()
	Grimoire.reset()


func test_slots() -> void:
	var pages := _build()
	var slots := _find(pages[0], BookSlot)
	check_eq(slots.size(), SpreadDigitalis.FORMS.size(), "Ein Platz pro Form")
	for slot: BookSlot in slots:
		var known := Grimoire.known_forms().has(String(slot.data))
		check_eq(slot.state == BookSlot.State.KNOWN, known, "Platz %s: bekannt nur, wenn die Form bekannt ist" % slot.data)
		if known:
			check(slot.icon != null, "Bekannte Form %s mit Bild" % slot.data)
	_free(pages)


func test_level_and_hint_before_gnarl() -> void:
	var pages := _build()
	var text := _text(pages[1])
	check(text.contains(tr("DIGITALIS_STAFF")), "Name der Form")
	check(text.contains(tr("BOOK_LEVEL") % 1), "Stufe 1")
	check(text.contains(tr("DIGITALIS_GNARL_HINT")), "Vor Gnarls Umzug nur der Hinweis")
	check(not text.contains(Inventory.display_name_for("cave_crystal")), "Noch keine Materialien")
	var notches := _find(pages[1], SpreadDigitalis.Notches)
	check(notches.size() == 1 and notches[0].total == 2 and notches[0].filled == 1, "Kerben: 1 von 2")
	_free(pages)


func test_needs_in_workshop() -> void:
	WorldState.set_flag("gnarl_moved")
	Inventory.add("cave_crystal", 2)
	var pages := _build()
	var text := _text(pages[1])
	check(text.contains(tr("DIGITALIS_GNARL_NEEDS") % tr("UPGRADE_STAFF_2")), "Was Gnarl für Stab II braucht")
	check(text.contains(Inventory.display_name_for("cave_crystal")), "Höhlenkristall genannt")
	check(text.contains(Inventory.display_name_for("bitterbloom_petal")), "Bitterblütenblatt genannt")
	check_eq(_find(pages[1], SpreadDiscipline.Check).size(), 1, "Kristalle da (Haken)")
	check(text.contains(tr("BOOK_HAVE_MISSING")), "Blätter fehlen")
	_free(pages)


func test_after_upgrade() -> void:
	WorldState.set_flag("gnarl_moved")
	Grimoire.grant(load("res://data/trades/gnarl/b_staff_2.tres").reward)
	var pages := _build()
	var text := _text(pages[1])
	check(text.contains(tr("BOOK_LEVEL") % 2), "Stufe 2")
	check(text.contains(tr("DIGITALIS_STAFF_UPGRADE_2")), "Was Stab II kann")
	check(text.contains(tr("DIGITALIS_FULLY_CARVED")), "Ganz ausgebaut")
	var notches := _find(pages[1], SpreadDigitalis.Notches)
	check(notches.size() == 1 and notches[0].filled == 2, "Kerben: 2 von 2")
	var staff_slot: Array = _find(pages[0], BookSlot).filter(func(s: BookSlot) -> bool: return s.data == "staff")
	check(staff_slot.size() == 1 and staff_slot[0].marked, "Goldenes Quadrat bei voller Stufe")
	_free(pages)


func test_texts_for_every_form_and_level() -> void:
	for form_id in Grimoire.START_FORMS:
		var key := "DIGITALIS_" + form_id.to_upper()
		for part in ["_LIGHT", "_HEAVY", "_WORLD"]:
			check(tr(key + part) != key + part, "Text fehlt: %s" % (key + part))
		for stage in range(2, SpreadDigitalis.max_level(form_id) + 1):
			check(tr("%s_UPGRADE_%d" % [key, stage]) != "%s_UPGRADE_%d" % [key, stage], "Upgrade-Text fehlt: %s %d" % [form_id, stage])
			check(SpreadDigitalis.next_offer(form_id) != null, "Gnarl hat ein Angebot für %s Stufe %d" % [form_id, stage])


func test_book_uses_digitalis_spread() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/grimoire/grimoire_book.gd")
	check(source.contains("SpreadDigitalis.new"), "Das Buch baut das Kapitel mit SpreadDigitalis")


# --- Hilfen ---------------------------------------------------------------

func _build() -> Array[Control]:
	var spread := SpreadDigitalis.new(null, CHAPTER)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	spread.build(left, right)
	return [left, right]


func _free(pages: Array[Control]) -> void:
	for page in pages:
		page.free()


func _find(root: Node, type: Variant) -> Array:
	return root.find_children("*", "", true, false).filter(func(n: Node) -> bool: return is_instance_of(n, type))


## Alle Texte auf der Seite, übersetzt, in einem String.
func _text(root: Node) -> String:
	var parts: PackedStringArray = []
	for node in root.find_children("*", "", true, false):
		if node is Label:
			parts.append(tr((node as Label).text))
		elif node is Button:
			parts.append(tr((node as Button).text))
	return "\n".join(parts)
