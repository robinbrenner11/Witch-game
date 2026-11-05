extends SceneTree

## Screenshot aus dem laufenden Spiel, für Prüfungen ohne Bildschirm (Cloud).
## Startet main.tscn, stellt Ort, Uhrzeit, Flags und Tasche ein, öffnet bei
## Bedarf das Grimoire und speichert ein Bild in 1280×720.
##
## Braucht echtes Rendern, also nicht --headless, sondern z. B. unter Xvfb:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##     --script res://tools/qa/screenshot.gd -- out=/tmp/bild.png \
##     level=res://scenes/world/forest.tscn exit=ToLakewood hour=22 \
##     flags=gnarl_moved,met_gnarl items=cave_crystal:2 book=digitalis
##
## scene=res://… nimmt statt des Spiels eine andere Szene (z. B. den Titel).
## lang=de stellt die Sprache um.
## Alle Angaben sind optional. pos=x,y setzt die Hexe direkt an eine Stelle.
## frames=N wartet so viele Frames vor dem Bild (Standard 60).

func _initialize() -> void:
	# Erst einen Frame warten, damit die Autoloads bereit sind. Sie werden
	# über ihren Pfad geholt: Ein --script kennt ihre Namen beim Übersetzen nicht.
	await process_frame
	var world_state := root.get_node("WorldState")
	var inventory := root.get_node("Inventory")
	var day_cycle := root.get_node("DayCycle")
	var grimoire := root.get_node("Grimoire")
	var args := _args()
	# Wie „Neues Spiel“ im Titelbildschirm: alle Systeme auf Anfang.
	root.get_node("SaveGame").new_game()
	for flag in String(args.get("flags", "")).split(",", false):
		world_state.set_flag(flag)
	for entry in String(args.get("items", "")).split(",", false):
		var parts := entry.split(":")
		inventory.add(parts[0], int(parts[1]) if parts.size() > 1 else 1)
	if args.has("lang"):
		TranslationServer.set_locale(String(args["lang"]))
	if args.has("hour"):
		day_cycle.minutes = float(args["hour"]) * 60.0
	if args.has("scene"):
		# Eine andere Szene als das Spiel, z. B. der Titelbildschirm.
		root.add_child(load(String(args["scene"])).instantiate())
		await _shoot(args)
		return
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if args.has("level"):
		main._load_level(String(args["level"]))
		var exit: Node2D = main.level.find_exit(String(args.get("exit", ""))) if args.has("exit") else null
		if exit:
			main.player.global_position = exit.spawn_position()
	if args.has("pos"):
		var xy := String(args["pos"]).split(",")
		main.player.global_position = Vector2(float(xy[0]), float(xy[1]))
	main.player.camera.reset_smoothing()
	if args.has("book"):
		grimoire.has_book = true
		var book := root.get_tree().get_first_node_in_group("grimoire_book")
		book.open(String(args["book"]))
	await _shoot(args)


func _shoot(args: Dictionary) -> void:
	for i in int(args.get("frames", 60)):
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var out := String(args.get("out", "user://screenshot.png"))
	image.save_png(out)
	print("Screenshot gespeichert: %s (%s)" % [out, image.get_size()])
	quit()


func _args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		result[parts[0]] = parts[1] if parts.size() > 1 else ""
	return result
