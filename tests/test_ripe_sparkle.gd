## Reife Pflanzen funkeln ab und zu, damit man auf Abstand sieht, welches
## Beet erntereif ist; unreife nicht.
extends TestCase


func test_only_ripe_plants_sparkle() -> void:
	for path in TestCase.files_under("res://data/plants", ["tres"]):
		var data := load(path) as PlantData
		var plant := (load("res://scenes/plants/plant.tscn") as PackedScene).instantiate() as Plant
		plant.data = data
		tree.root.add_child(plant)
		plant.growth_stage = 0
		check(not plant._sparkle.active, "%s: Samen funkelt nicht" % data.id)
		plant.growth_stage = data.stage_count - 2
		check(not plant._sparkle.active, "%s: fast reif funkelt noch nicht" % data.id)
		plant.growth_stage = data.stage_count - 1
		check(plant._sparkle.active, "%s: reif funkelt" % data.id)
		# Nach spätestens einer langen Pause blitzt es einmal auf.
		var seen := false
		for i in 300:
			plant._sparkle._process(1.0 / 60.0)
			if plant._sparkle.is_sparkling():
				seen = true
				break
		check(seen, "%s: das Funkeln erscheint" % data.id)
		plant.queue_free()
	await tree.process_frame
