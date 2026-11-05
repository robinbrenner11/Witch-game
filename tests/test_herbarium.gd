## Herbarium: Jeder Gegenstand, den man finden kann (alles außer Tränken und
## Werkzeug), hat einen Eintrag, und jeder Eintrag lässt sich im Spiel auch
## wirklich entdecken.
extends TestCase

const ITEM_FOLDER := "res://data/items/"
# Aktionen, die das Spiel über Grimoire.report meldet und die ein Eintrag als
# Auslöser benutzen darf. Kommt eine neue dazu, hier ergänzen.
const KNOWN_ACTIONS := ["plant", "harvest", "forage", "clear", "obtain", "cleanse"]
# Die Einträge aus dem Backlog („Herbarium-Einträge für die neuen Items“).
const NEW_ITEMS := ["cave_crystal", "willow_bark", "moon_water", "swamp_light",
		"bloom_bud", "moonmoss", "owl_feather", "bitterbloom_petal"]


func before_each() -> void:
	Grimoire.reset()
	Inventory.reset()
	WorldState.reset()


func test_every_findable_item_has_entry() -> void:
	for item: ItemData in DataFolder.load_all(ITEM_FOLDER):
		if item.type == ItemData.Type.POTION or item.type == ItemData.Type.TOOL:
			continue
		var entry := EntryData.for_item(item.id)
		check(entry != null, "Kein Herbarium-Eintrag für %s" % item.id)
		if entry:
			check_eq(entry.chapter, "herbarium", "Eintrag für %s liegt im Herbarium" % item.id)


func test_new_items_have_entries() -> void:
	for item_id in NEW_ITEMS:
		check(EntryData.for_item(item_id) != null, "Kein Eintrag für %s" % item_id)


func test_entries_are_complete() -> void:
	var ids: Array[String] = []
	for entry in EntryData.in_chapter("herbarium"):
		check(not ids.has(entry.id), "Eintrag doppelt: %s" % entry.id)
		ids.append(entry.id)
		check(_translated(entry.title_key), "Titel ohne Text: %s" % entry.id)
		check(_translated("BOOK_GROUP_" + entry.page_group.to_upper()), "Seite ohne Namen: %s" % entry.page_group)
		check(entry.facts.size() > 0, "Eintrag ohne Fakten: %s" % entry.id)
		check_eq(entry.fact_triggers.size(), entry.facts.size(), "Auslöser je Fakt bei %s" % entry.id)
		for fact in entry.facts:
			check(_translated(fact), "Fakt ohne Text: %s" % fact)
		for item_id in entry.item_ids:
			check(Inventory.icon_for(item_id) != null, "%s: Item %s ohne Icon" % [entry.id, item_id])
		check(_action_known(entry.discover_on), "%s: unbekannter Auslöser %s" % [entry.id, entry.discover_on])
		for trigger in entry.fact_triggers:
			if trigger != "":
				check(_action_known(trigger.split(":")[0]), "%s: unbekannter Auslöser %s" % [entry.id, trigger])


## Jede Seite (page_group) bringt genau eine Belohnung, wenn sie voll ist.
func test_every_page_has_one_reward() -> void:
	var rewards := {}
	for entry in EntryData.in_chapter("herbarium"):
		rewards[entry.page_group] = int(rewards.get(entry.page_group, 0)) + (1 if entry.page_reward else 0)
	for group in rewards:
		check_eq(rewards[group], 1, "Belohnungen auf Seite %s" % group)


func test_forage_reveals_facts() -> void:
	var entry := EntryData.for_item("willow_bark")
	check(not Grimoire.is_discovered(entry), "Weidenrinde am Anfang unbekannt")
	Grimoire.report("forage", {"id": "willow_bark"})
	check(Grimoire.is_discovered(entry), "Weidenrinde nach dem Sammeln entdeckt")
	check_eq(Grimoire.revealed_facts(entry), 1, "Ein Fakt nach dem ersten Sammeln")
	for i in 4:
		Grimoire.report("forage", {"id": "willow_bark"})
	check(Grimoire.is_entry_complete(entry), "Alle Fakten nach fünfmal Sammeln")


func test_trade_discovers_bloom_bud() -> void:
	var offer := load("res://data/trades/ugo/c_mending_for_bud.tres") as TradeOffer
	var entry := EntryData.for_item("bloom_bud")
	Inventory.add("potion_mending")
	check(offer.trade("ugo"), "Tausch klappt")
	check(Grimoire.is_discovered(entry), "Blütenknospe nach dem Tausch entdeckt")


func test_picking_up_petal_discovers_it() -> void:
	var entry := EntryData.for_item("bitterbloom_petal")
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	var drop := DroppedItem.new()
	drop.item_id = "bitterbloom_petal"
	drop._on_body_entered(player)
	check_eq(Inventory.count("bitterbloom_petal"), 1, "Blatt liegt in der Tasche")
	check(Grimoire.is_discovered(entry), "Blatt nach dem Aufheben entdeckt")
	drop.free()
	player.free()


## Volle Seite „Jenseits des Waldes“ bringt einmal Wildcraft-Erfahrung.
func test_full_page_grants_reward_once() -> void:
	var before := Grimoire.xp("wildcraft")
	var entries := EntryData.in_chapter("herbarium").filter(
			func(e: EntryData) -> bool: return e.page_group == "beyond")
	check(entries.size() == 4, "Vier Einträge auf der Seite (ist: %d)" % entries.size())
	for entry: EntryData in entries:
		for i in 6:
			var parts := entry.discover_on.split("/")
			Grimoire.report(parts[0], {"id": parts[1]})
		check(Grimoire.is_entry_complete(entry), "%s nach sechsmal vollständig" % entry.id)
	check(Grimoire.is_group_complete("herbarium", "beyond"), "Seite voll")
	var after := Grimoire.xp("wildcraft")
	check(after >= before + 60, "Belohnung gutgeschrieben")
	var parts: PackedStringArray = (entries[0] as EntryData).discover_on.split("/")
	Grimoire.report(parts[0], {"id": parts[1]})
	# Danach gibt es nur noch die normale Sammel-Erfahrung, keine zweite Belohnung.
	check(Grimoire.xp("wildcraft") < after + 60, "Belohnung nur einmal")


func _translated(key: String) -> bool:
	return TranslationServer.translate(key) != StringName(key)


func _action_known(event: String) -> bool:
	var parts := event.split("/")
	return parts.size() == 2 and parts[1] != "" and parts[0] in KNOWN_ACTIONS
