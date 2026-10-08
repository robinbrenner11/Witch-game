class_name SpreadHerbarium
extends GrimoireSpread

## Herbarium (später auch Bestiary): links die Einträge nach Seiten
## gruppiert, rechts der gewählte Eintrag mit seinen Fakten. Alles hier hat
## die Spielerin selbst entdeckt, deshalb steht es in ihrer Tinte (Magenta).
## Noch verborgene Fakten sind Fragezeichen. Volle Seiten bringen eine
## Belohnung. Design: docs/design/grimoire.md, Abschnitt 1.

const COLUMNS := 6

var selected: EntryData


static func seen_key(entry: EntryData) -> String:
	return "entry/%s/%d" % [entry.id, Grimoire.revealed_facts(entry)]


func has_new() -> bool:
	for entry in EntryData.in_chapter(chapter.id):
		if Grimoire.is_discovered(entry) and not Grimoire.is_seen(seen_key(entry)):
			return true
	return false


## Aus einem Rezept heraus direkt zu einer Zutat springen.
func select_item(item_id: String) -> void:
	var entry := EntryData.for_item(item_id)
	if entry:
		selected = entry


func build(left: Control, right: Control) -> void:
	var entries := EntryData.in_chapter(chapter.id)
	if selected == null:
		for entry in entries:
			if Grimoire.is_discovered(entry):
				selected = entry
				break
	_build_index(left, entries)
	if selected and Grimoire.is_discovered(selected):
		_build_detail(right, selected)
		Grimoire.mark_seen(seen_key(selected))
	elif selected:
		right.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
		right.add_child(BookStyle.label("BOOK_ENTRY_UNKNOWN", BookStyle.INK_FAINT, text_width))


func _build_index(page: Control, entries: Array[EntryData]) -> void:
	var discovered := entries.filter(func(e: EntryData) -> bool: return Grimoire.is_discovered(e)).size()
	var header := HBoxContainer.new()
	header.add_child(BookStyle.label(chapter.title_key, BookStyle.INK_VESPERA_TITLE))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(BookStyle.label("%d/%d" % [discovered, entries.size()], BookStyle.INK_FAINT))
	var moon := SpreadRecipes.CompletionMoon.new()
	moon.fraction = float(discovered) / maxf(entries.size(), 1)
	header.add_child(moon)
	page.add_child(header)
	page.add_child(BookStyle.rule(text_width))

	var groups: Array[String] = []
	for entry in entries:
		if not groups.has(entry.page_group):
			groups.append(entry.page_group)
	for group in groups:
		var complete := Grimoire.is_group_complete(chapter.id, group)
		page.add_child(BookStyle.label("BOOK_GROUP_" + group.to_upper(), BookStyle.GOLD_DARK if complete else BookStyle.INK))
		var reward := _group_reward(group)
		if reward and not complete:
			page.add_child(BookStyle.label(tr("BOOK_PAGE_REWARD") % SpreadDiscipline.reward_text(reward), BookStyle.INK_FAINT, text_width))
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for entry in entries:
			if entry.page_group == group:
				grid.add_child(_slot(entry))
		page.add_child(grid)


func _slot(entry: EntryData) -> BookSlot:
	var slot := BookSlot.new()
	slot.data = entry
	slot.icon = _icon_of(entry)
	slot.state = BookSlot.State.KNOWN if Grimoire.is_discovered(entry) else BookSlot.State.UNKNOWN
	slot.selected = entry == selected
	# Goldenes Quadrat: alle Fakten aufgedeckt.
	slot.marked = Grimoire.is_entry_complete(entry)
	slot.is_new = Grimoire.is_discovered(entry) and not Grimoire.is_seen(seen_key(entry))
	slot.chosen.connect(func(s: BookSlot) -> void:
		selected = s.data
		book.refresh())
	return slot


func _group_reward(group: String) -> RewardData:
	for entry in EntryData.in_chapter(chapter.id):
		if entry.page_group == group and entry.page_reward:
			return entry.page_reward
	return null


## Ohne eigenes Bild nimmt der Eintrag das Icon seines ersten Items.
func _icon_of(entry: EntryData) -> Texture2D:
	return entry.icon if entry.icon else Inventory.icon_for(entry.item_ids[0])


func _build_detail(page: Control, entry: EntryData) -> void:
	page.add_child(BookStyle.heading(entry.title_key, BookStyle.INK_PLAYER, text_width))
	var row := HBoxContainer.new()
	row.add_child(BookStyle.icon(_icon_of(entry)))
	page.add_child(row)
	var revealed := Grimoire.revealed_facts(entry)
	page.add_child(BookStyle.label(tr("BOOK_FACTS") % [revealed, entry.facts.size()], BookStyle.INK_FAINT))
	for i in entry.facts.size():
		if i < revealed:
			page.add_child(BookStyle.label(entry.facts[i], BookStyle.INK_PLAYER, text_width))
		else:
			page.add_child(BookStyle.label("???", BookStyle.INK_FAINT))
