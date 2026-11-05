## Bestiarium: öffnet sich mit dem ersten gereinigten Wesen, jede Käferart hat
## einen Eintrag mit Verhalten, Schwäche und Beute.
extends TestCase

const CHAPTER := preload("res://data/grimoire/chapters/bestiary.tres")
const ENEMY_SCENES := ["res://scenes/world/blight_beetle.tscn", "res://scenes/world/blight_beetle_horned.tscn"]


func before_each() -> void:
	SaveGame.new_game()
	Grimoire.find_book()


func test_unlocks_with_first_cleanse() -> void:
	check(not Grimoire.is_unlocked(CHAPTER), "Vor dem ersten Kampf versiegelt")
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	check(Grimoire.is_unlocked(CHAPTER), "Nach der ersten Reinigung offen")


func test_every_enemy_has_entry() -> void:
	var beasts := EntryData.in_chapter("bestiary")
	for path in ENEMY_SCENES:
		var enemy := (load(path) as PackedScene).instantiate()
		var found := beasts.filter(func(e: EntryData) -> bool: return e.discover_on == "cleanse/" + enemy.enemy_id)
		check_eq(found.size(), 1, "Eintrag für %s" % enemy.enemy_id)
		if found.size() == 1:
			var entry: EntryData = found[0]
			check(entry.icon != null, "Bild für %s" % enemy.enemy_id)
			check(tr(entry.title_key) != entry.title_key, "Name für %s" % enemy.enemy_id)
			for fact in entry.facts:
				check(tr(fact) != fact, "Text fehlt: %s" % fact)
		enemy.free()


func test_discovery_message_names_bestiary() -> void:
	var messages: Array[String] = []
	var listener := func(text: String) -> void: messages.append(text)
	Messages.posted.connect(listener)
	Grimoire.report("cleanse", {"id": "blight_beetle_horned"})
	Messages.posted.disconnect(listener)
	var expected := tr("MSG_CREATURE_DISCOVERED") % tr("BEAST_BLIGHT_BEETLE_HORNED")
	check(messages.has(expected), "Meldung nennt das Bestiarium: %s" % str(messages))


func test_spread_shows_beetle() -> void:
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	var spread := SpreadHerbarium.new(null, CHAPTER)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	spread.build(left, right)
	check_eq(left.find_children("*", "BookSlot", true, false).size(), EntryData.in_chapter("bestiary").size(), "Ein Platz pro Wesen")
	var labels := right.find_children("*", "Label", true, false).map(func(l: Label) -> String: return tr(l.text))
	check(labels.has(tr("BEAST_BLIGHT_BEETLE_1")), "Erster Fakt zum Käfer steht rechts")
	left.free()
	right.free()
