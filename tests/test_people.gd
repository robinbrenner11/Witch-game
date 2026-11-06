## People-Kapitel: Jede Person hat einen Eintrag, der beim ersten Gespräch
## entdeckt wird; weitere Eindrücke (in der Tinte der Spielerin) decken sich
## durch weitere Gespräche auf.
extends TestCase


func before_each() -> void:
	Grimoire.reset()


func test_every_npc_has_entry() -> void:
	var people := EntryData.in_chapter("people")
	for npc: NpcData in DataFolder.load_all("res://data/npcs/"):
		var found := people.filter(func(e: EntryData) -> bool: return e.discover_on == "talk/" + npc.id)
		check_eq(found.size(), 1, "Eintrag für %s" % npc.id)
		if found.size() == 1:
			var entry: EntryData = found[0]
			check_eq(entry.title_key, npc.name_key, "Name von %s" % npc.id)
			check(entry.icon != null, "Bild für %s" % npc.id)
			check_eq(entry.fact_triggers.size(), entry.facts.size(), "Auslöser je Eindruck bei %s" % npc.id)
			for fact in entry.facts:
				check(tr(fact) != fact, "Text fehlt: %s" % fact)


func test_talking_reveals_impressions() -> void:
	var entry: EntryData = EntryData.in_chapter("people").filter(
			func(e: EntryData) -> bool: return e.id == "people_gnarl")[0]
	check(not Grimoire.is_discovered(entry), "Vor dem ersten Gespräch unbekannt")
	Grimoire.report("talk", {"id": "gnarl"})
	check(Grimoire.is_discovered(entry), "Nach dem ersten Gespräch entdeckt")
	check_eq(Grimoire.revealed_facts(entry), 1, "Ein Eindruck")
	for i in 5:
		Grimoire.report("talk", {"id": "gnarl"})
	check(Grimoire.is_entry_complete(entry), "Nach sechs Gesprächen alle Eindrücke")


func test_book_shows_people_like_herbarium() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/grimoire/grimoire_book.gd")
	check(source.contains("\"herbarium\", \"bestiary\", \"people\""), "People nutzt die Eintrags-Doppelseite")
	Grimoire.report("talk", {"id": "watchman"})
	var spread := SpreadHerbarium.new(null, load("res://data/grimoire/chapters/people.tres"))
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	spread.build(left, right)
	var slots := left.find_children("*", "BookSlot", true, false)
	check_eq(slots.size(), EntryData.in_chapter("people").size(), "Ein Platz pro Person")
	var labels := right.find_children("*", "Label", true, false).map(func(l: Label) -> String: return tr(l.text))
	check(labels.has(tr("PEOPLE_WATCHMAN_1")), "Erster Eindruck vom Nachtwächter steht rechts")
	left.free()
	right.free()


## Unter dem Namen steht, wer die Person ist (Rollentext aus den NPC-Daten).
func test_entry_shows_role() -> void:
	for npc: NpcData in DataFolder.load_all("res://data/npcs/"):
		var entry: EntryData = EntryData.in_chapter("people").filter(
				func(e: EntryData) -> bool: return e.discover_on == "talk/" + npc.id)[0]
		check_eq(entry.subtitle_key, npc.role_key, "Rolle von %s" % npc.id)
