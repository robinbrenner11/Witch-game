## Die Eule fliegt auf, wenn die Hexe zu nah an ihren Baum kommt, und sitzt
## später wieder auf dem Ast, wenn die Hexe weg ist.
extends TestCase


func test_flies_away_and_returns() -> void:
	var owl := (load("res://scenes/world/owl.tscn") as PackedScene).instantiate()
	var witch := Node2D.new()
	witch.add_to_group("player")
	tree.root.add_child(owl)
	tree.root.add_child(witch)
	owl.global_position = Vector2(300, 300)
	witch.global_position = Vector2(600, 300)
	await tree.process_frame
	check_eq(owl.mood, owl.Mood.PERCHED, "Sitzt, solange die Hexe weit weg ist")
	witch.global_position = owl.global_position + Vector2(20, 10)
	await tree.process_frame
	check_eq(owl.mood, owl.Mood.FLYING, "Fliegt auf, wenn die Hexe nah kommt")
	check(owl._fly_sprites[0].visible and not owl._sprites[0].visible, "Flug-Bild statt Sitz-Bild")
	# Echte Zeit abwarten (headless laufen Frames schneller als die Uhr).
	await tree.create_timer(owl.FLIGHT_TIME + 0.5).timeout
	check_eq(owl.mood, owl.Mood.AWAY, "Nach dem Flug weg")
	check(not owl._fly_sprites[0].visible, "Nicht mehr zu sehen")
	# Bleibt weg, solange die Hexe in der Nähe ist, auch nach langer Zeit.
	owl._away_time = owl.RETURN_TIME + 1.0
	await tree.process_frame
	check_eq(owl.mood, owl.Mood.AWAY, "Kommt nicht zurück, solange die Hexe nah ist")
	witch.global_position = Vector2(800, 300)
	await tree.process_frame
	check_eq(owl.mood, owl.Mood.PERCHED, "Wieder auf dem Ast, wenn die Hexe weg ist")
	check(owl._sprites[0].visible, "Sitz-Bild wieder da")
	owl.queue_free()
	witch.queue_free()
	await tree.process_frame
