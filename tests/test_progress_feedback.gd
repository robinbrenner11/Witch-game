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
