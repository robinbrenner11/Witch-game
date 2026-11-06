## Hexenring als Schnellreise: schläft bis zur Heilung (Blütenherz), dann
## führt er zu den anderen wachen Ringen. Ankunft über Level.find_spawn.
extends TestCase

var holder: Node2D


func before_each() -> void:
	SaveGame.new_game()
	holder = Node2D.new()
	tree.root.add_child(holder)


func after_each() -> void:
	holder.queue_free()
	await tree.process_frame


func test_sleeps_until_healed() -> void:
	var ring := (load("res://scenes/world/witch_ring.tscn") as PackedScene).instantiate() as WitchRing
	ring.ring_id = "forest"
	holder.add_child(ring)
	await tree.process_frame
	check(not ring.is_awake(), "Vor dem Blütenherz schläft der Ring")
	check_eq(ring.interaction_prompt(), "PROMPT_LOOK", "Nur anschauen")
	WorldState.set_flag(BloomHeart.CLEANSED_FLAG)
	check(ring.is_awake(), "Nach der Heilung wach")
	check_eq(ring.destinations(), ["garden"] as Array[String], "Vom Wald in den Garten")
	check_eq(ring.interaction_prompt(), "PROMPT_RING_TRAVEL", "Hineintreten")


func test_every_ring_exists_in_its_place() -> void:
	for id: String in WitchRing.NETWORK:
		var level := (load(WitchRing.NETWORK[id]["scene"]) as PackedScene).instantiate() as Level
		var spawn := level.find_spawn(WitchRing.NODE_PREFIX + id)
		check(spawn is WitchRing, "%s: Ring %s gefunden" % [level.name, id])
		if spawn:
			check_eq((spawn as WitchRing).ring_id, id, "Richtige ID")
		level.free()


func test_exits_still_found_as_spawns() -> void:
	var forest := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate() as Level
	check(forest.find_spawn("ToLakewood") is Exit, "Ausgänge sind weiter Ankunftsorte")
	check(forest.find_spawn("Ground") == null, "Andere Nodes nicht")
	forest.free()
