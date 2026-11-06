## Ende Akt 1: Blütennebel (S5), Turmruine und das erste Blütenherz.
## Nebel öffnet mit Reinigungsnebel nur für die Nacht, das Herz kämpft in drei
## Phasen (Schildknospen in Phase 3), gereinigt heilt es den Wald für immer.
extends TestCase

var holder: Node2D


func before_each() -> void:
	SaveGame.new_game()
	holder = Node2D.new()
	tree.root.add_child(holder)


func after_each() -> void:
	holder.queue_free()
	await tree.process_frame


func _heart() -> BloomHeart:
	var heart := BloomHeart.new()
	holder.add_child(heart)
	return heart


func test_mist_opens_only_for_the_night() -> void:
	var forest := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate()
	holder.add_child(forest)
	await tree.process_frame
	var mist := forest.get_node("BloomMist") as Gate
	check(not mist.is_open(), "Nebel anfangs zu")
	check(mist.on_potion(ItemData.from_id("potion_cleansing_mist")), "Reinigungsnebel wirkt")
	check(mist.is_open(), "Heute Nacht offen")
	DayCycle.sleep_until_night()
	check(not mist.is_open(), "Nächste Nacht wieder zu")
	WorldState.set_flag(BloomHeart.CLEANSED_FLAG)
	check(mist.is_open(), "Nach dem Herz für immer offen")
	check(ResourceLoader.exists(forest.get_node("ToTowerRuin").target_scene), "Weg zur Turmruine")
	forest.free()


func test_awakens_and_phases() -> void:
	var heart := _heart()
	await tree.process_frame
	check_eq(heart.state, BloomHeart.State.DORMANT, "Schläft, bis man kommt")
	heart.take_hit(1, Vector2.ZERO)
	check_eq(heart.state, BloomHeart.State.FIGHT, "Ein Treffer weckt es")
	heart.take_hit(heart.max_health / 3, Vector2.ZERO)
	check_eq(heart.phase, 2, "Phase 2 nach einem Drittel")
	await tree.process_frame
	var beetles := holder.get_children().filter(func(n: Node) -> bool: return n is BlightBeetle)
	check_eq(beetles.size(), 2, "Phase 2 ruft zwei Käfer")
	heart.take_hit(heart.max_health / 3, Vector2.ZERO)
	check_eq(heart.phase, 3, "Phase 3")
	await tree.process_frame
	check(heart.is_shielded(), "Schildknospen schützen")
	var before := heart.health
	heart.take_hit(5, Vector2.ZERO)
	check_eq(heart.health, before, "Geschützt: kein Schaden")
	for bud in holder.get_children().filter(func(n: Node) -> bool: return n is BloomBud):
		(bud as BloomBud).take_hit(BloomBud.MAX_HEALTH, Vector2.ZERO)
	check(not heart.is_shielded(), "Knospen geplatzt: Schild weg")
	heart.take_hit(1, Vector2.ZERO)
	check_eq(heart.health, before - 1, "Wieder verwundbar")


func test_attacks_are_telegraphed() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	holder.add_child(player)
	player.global_position = Vector2(0, 150)
	var heart := _heart()
	await tree.process_frame
	heart.awaken()
	heart._attack()
	var hazards := holder.get_children().filter(func(n: Node) -> bool: return n is BloomHazard)
	check(hazards.size() >= 3, "Phase 1: mehrere Sporenkreise")
	for hazard: BloomHazard in hazards:
		check(hazard.warn_time >= 0.8, "Deutliche Vorwarnung")
	var ray := BloomHazard.new()
	ray.shape = BloomHazard.Shape.RAY
	ray.direction = Vector2.RIGHT
	ray.length = 100.0
	ray.width = 16.0
	holder.add_child(ray)
	check(ray.covers(Vector2(50, 4)), "Im Strahl getroffen")
	check(not ray.covers(Vector2(50, 30)), "Daneben sicher")
	check(not ray.covers(Vector2(-20, 0)), "Hinter dem Ursprung sicher")
	player.free()


func test_hazard_hurts_witch() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	holder.add_child(player)
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	var start := vitals.health
	var spore := BloomHazard.new()
	spore.warn_time = 0.05
	holder.add_child(spore)
	spore.global_position = player.global_position
	await tree.create_timer(0.15).timeout
	check_eq(vitals.health, start - 1, "Wer drinsteht, nimmt Schaden")


func test_cleanse_heals_for_good() -> void:
	var heart := _heart()
	await tree.process_frame
	heart.take_hit(heart.max_health * 2, Vector2.ZERO)
	await tree.process_frame
	for bud in holder.get_children().filter(func(n: Node) -> bool: return n is BloomBud):
		(bud as BloomBud).take_hit(9, Vector2.ZERO)
	heart.take_hit(heart.max_health * 2, Vector2.ZERO)
	check_eq(heart.state, BloomHeart.State.CLEANSED, "Gereinigt")
	check(WorldState.has_flag(BloomHeart.CLEANSED_FLAG), "Flag gesetzt")
	check_eq(Grimoire.count_of("cleanse/bloom_heart"), 1, "Grimoire weiß davon")
	check(not heart.is_in_group("blighted"), "Nicht mehr befallen")
	await tree.process_frame
	var buds := holder.get_children().filter(func(n: Node) -> bool: return n is DroppedItem)
	check_eq(buds.size(), 3, "Drei Blütenknospen")
	var pages := holder.get_children().filter(func(n: Node) -> bool: return n.get("page_id") == BloomHeart.KEY_PAGE)
	check_eq(pages.size(), 1, "Schlüsselseite liegt da")
	var again := _heart()
	await tree.process_frame
	check_eq(again.state, BloomHeart.State.CLEANSED, "Beim nächsten Besuch schon gereinigt")
	check(not again.is_in_group("blighted"), "Kein Gegner mehr")


func test_forest_heals() -> void:
	var forest := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate()
	holder.add_child(forest)
	await tree.process_frame
	check((forest.get_node("BlightArea") as CanvasItem).visible, "Befall sichtbar")
	WorldState.set_flag(BloomHeart.CLEANSED_FLAG)
	await tree.process_frame
	check(not (forest.get_node("BlightArea") as CanvasItem).visible, "Befall weicht")
	check_eq(String(forest.get_node("WildBeetles").blocked_by_flag), BloomHeart.CLEANSED_FLAG, "Keine neuen Käfer außer bei Neumond")
	forest.free()


func test_watchman_points_to_the_mist() -> void:
	for flag in ["met_watchman", "met_gnarl", "dlg_watchman_first_meeting", "dlg_watchman_rumor_mending", "dlg_watchman_rumor_ember", "dlg_watchman_rumor_growth"]:
		WorldState.set_flag(flag)
	var rumor := DialogueData.pick("watchman", "rumor")
	check(rumor != null and rumor.id == "rumor_mist", "Nachtwächter erzählt vom Nebel")
	WorldState.set_flag(BloomHeart.CLEANSED_FLAG)
	var talk := DialogueData.pick("watchman", "")
	check(talk != null and talk.id == "heart_cleansed", "Nachtwächter dankt nach der Heilung")
