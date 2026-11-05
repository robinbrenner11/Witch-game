## Stufenaufstieg wird spürbar: Klang vorhanden, Funken um die Hexe.
extends TestCase


func before_each() -> void:
	SaveGame.new_game()


func test_level_up_sound_exists() -> void:
	check(ResourceLoader.exists("res://assets/audio/sfx/ui/level_up.wav"), "Klang ui/level_up liegt bereit")


func test_level_up_shows_motes() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	var objects: Node = main.level.objects
	var before := objects.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D).size()
	Grimoire.add_xp("wildcraft", 1000)
	await tree.process_frame
	var after := objects.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D).size()
	check(after >= before + 2, "Funken erscheinen beim Aufstieg (%d → %d)" % [before, after])
	main.queue_free()
	await tree.process_frame


func test_discovery_shows_motes() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	var objects: Node = main.level.objects
	var count := func() -> int: return objects.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D).size()
	var before: int = count.call()
	Grimoire.report("forage", {"id": "willow_bark"})
	await tree.process_frame
	check(count.call() > before, "Funken beim Entdecken eines Eintrags")
	# Beim zweiten Mal kein neues Entdecken (gezählt am Signal: Funken könnten
	# auch von einem Stufenaufstieg kommen).
	var discovered := [0]
	var counter := func(_e: EntryData) -> void: discovered[0] += 1
	Grimoire.entry_discovered.connect(counter)
	Grimoire.report("forage", {"id": "willow_bark"})
	Grimoire.entry_discovered.disconnect(counter)
	check_eq(discovered[0], 0, "Kein zweites Entdecken für denselben Eintrag")
	main.queue_free()
	await tree.process_frame
