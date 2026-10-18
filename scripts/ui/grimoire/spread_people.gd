class_name SpreadPeople
extends GrimoireSpread

## Kapitel People: links alle Personen als Raster (Unbekannte als ?),
## rechts die gewählte Person: Name, wo man sie findet, ihr Eindruck in der
## Handschrift der Spielerin und was sie tauscht. Wer jemanden kennt, steht
## als Flag "met_<id>" in WorldState (setzt der NPC beim ersten Gespräch).
## Freundschaft (5 Herzen) kommt mit dem Social-System.
## Design: docs/design/grimoire.md, Abschnitt 1 (People).

var _selected := ""


static func people() -> Array[NpcData]:
	var list: Array[NpcData] = []
	for resource in DataFolder.load_all(NpcData.FOLDER):
		list.append(resource as NpcData)
	list.sort_custom(func(a: NpcData, b: NpcData) -> bool: return a.book_order < b.book_order)
	return list


static func is_met(npc: NpcData) -> bool:
	return WorldState.has_flag("met_" + npc.id)


func has_new() -> bool:
	for npc in people():
		if is_met(npc) and not Grimoire.is_seen("person/" + npc.id):
			return true
	return false


func build(left: Control, right: Control) -> void:
	add_title(left)
	var list := people()
	if _selected == "":
		for npc in list:
			if is_met(npc):
				_selected = npc.id
				break
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	var chosen: NpcData = null
	for npc in list:
		var slot := BookSlot.new()
		slot.data = npc.id
		slot.state = BookSlot.State.KNOWN if is_met(npc) else BookSlot.State.UNKNOWN
		slot.icon = npc.book_icon if is_met(npc) else null
		slot.selected = npc.id == _selected
		slot.is_new = is_met(npc) and not Grimoire.is_seen("person/" + npc.id)
		slot.chosen.connect(func(s: BookSlot) -> void:
			_selected = s.data
			book.refresh())
		grid.add_child(slot)
		if npc.id == _selected:
			chosen = npc
	left.add_child(grid)
	if chosen and is_met(chosen):
		_build_detail(right, chosen)
		Grimoire.mark_seen("person/" + chosen.id)
	else:
		right.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
		right.add_child(BookStyle.label("PEOPLE_NOT_MET", BookStyle.INK_FAINT, text_width))


func _build_detail(page: Control, npc: NpcData) -> void:
	page.add_child(BookStyle.heading(npc.name_key, BookStyle.INK_VESPERA_TITLE, text_width))
	page.add_child(BookStyle.label(npc.role_key, BookStyle.INK, text_width))
	var places := _places(npc)
	if not places.is_empty():
		page.add_child(BookStyle.label(tr("BOOK_PERSON_WHERE") % ", ".join(places), BookStyle.INK_FAINT, text_width))
	if npc.impression_key != "":
		page.add_child(BookStyle.label(npc.impression_key, BookStyle.INK_PLAYER, text_width))
	var trades := _trade_goods(npc)
	if not trades.is_empty():
		page.add_child(BookStyle.rule(text_width))
		page.add_child(BookStyle.label(tr("BOOK_PERSON_TRADES") % ", ".join(trades), BookStyle.INK, text_width))


## Orte aus der Tagesroutine, ohne doppelte und ohne "drinnen".
func _places(npc: NpcData) -> PackedStringArray:
	var result: PackedStringArray = []
	for entry in npc.schedule:
		if entry.level == "" or entry.spot == "" and entry.patrol.is_empty():
			continue
		if entry.requires_flag != "" and not WorldState.has_flag(entry.requires_flag):
			continue
		if entry.blocked_by_flag != "" and WorldState.has_flag(entry.blocked_by_flag):
			continue
		var place := tr("PLACE_" + entry.level.to_upper())
		if not result.has(place):
			result.append(place)
	return result


## Was die Person hergibt (Items und Upgrades), ohne doppelte.
func _trade_goods(npc: NpcData) -> PackedStringArray:
	var result: PackedStringArray = []
	for offer in TradeOffer.all_for(npc.id):
		var good := ""
		if offer.reward and offer.reward.type == RewardData.Type.UPGRADE:
			good = tr("BOOK_PERSON_UPGRADES")
		elif offer.gives_item != "":
			good = Inventory.display_name_for(offer.gives_item)
		if good != "" and not result.has(good):
			result.append(good)
	return result
