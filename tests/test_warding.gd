## Bannkunst (Warding): Reinigen bringt Erfahrung, Stufen bringen Tränke und
## Lebenspunkte, Stufe 5 wählt Hexenklinge (Nahkampf) oder Hexenwirkerin
## (Hexenkraft). Das Kapitel öffnet sich mit dem ersten gereinigten Wesen.
extends TestCase


func before_each() -> void:
	SaveGame.new_game()
	Grimoire.find_book()


func test_unlocks_with_first_fight() -> void:
	var chapter: ChapterData = ChapterData.all().filter(func(c: ChapterData) -> bool: return c.id == "warding")[0]
	check(not Grimoire.is_unlocked(chapter), "Vor dem ersten Kampf versiegelt")
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	check(Grimoire.is_unlocked(chapter), "Nach dem ersten Käfer offen")


func test_cleansing_gives_xp() -> void:
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	var first := Grimoire.xp("warding")
	check(first >= 25, "Erstes Wesen einer Art bringt viel")
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	check(Grimoire.xp("warding") - first < first, "Wiederholung bringt weniger")


func test_health_grows_with_level() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	tree.root.add_child(player)
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	var base := vitals.max_hp()
	Grimoire.add_xp("warding", 80)
	check_eq(Grimoire.level("warding"), 2, "Stufe 2")
	check_eq(vitals.max_hp(), base + 2, "Stufe 2 gibt zwei Lebenspunkte mehr")
	player.queue_free()
	await tree.process_frame


func test_paths() -> void:
	Grimoire.add_xp("warding", 100000)
	check_eq(PathData.options("warding", 5, "").size(), 2, "Zwei Pfade auf Stufe 5")
	check(not 10 in DisciplineData.from_id("warding").milestone_levels, "Keine leere Wahl auf Stufe 10 (Pfade dort noch offen)")
	Grimoire.choose_path(PathData.from_id("warding_hexblade"))
	check_eq(Grimoire.get_stat("hexblade"), 1, "Hexenklinge: +1 Nahkampfschaden")
	check_eq(Grimoire.get_stat("hexcaster"), 0, "Nicht beides")


func test_heart_page_feeds_warding() -> void:
	var page := PageData.from_id(BloomHeart.KEY_PAGE)
	check_eq(page.reward.target_id, "warding", "Schlüsselseite des Herzens stärkt die Bannkunst")
