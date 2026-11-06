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
## lang=de stellt die Sprache um, name=Nyx gibt der Hexe einen Namen. garden=demo pflanzt Beete mit allen Pflanzen,
## brew=1 öffnet das Brau-Fenster, message=SCHLÜSSEL zeigt eine Meldung,
## press=aktion,… drückt Tasten, say=SCHLÜSSEL zeigt eine Zeile in der Dialogbox,
## interact=Pfad/im/Ort löst E an diesem Objekt aus, spawn=szene@x,y;… setzt Szenen,
## freeze=0.3 hält eingesetzte Käfer im Innehalten vor dem Anlauf fest,
## call=Pfad:methode:arg ruft eine Methode an einem Node unter main.tscn auf.
## map=1 zeigt den ganzen Ort auf einmal. day=N stellt die Nacht ein (und damit die Mondphase).
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
	# events=talk/gnarl:3,forage/moonmoss meldet Ereignisse ans Grimoire (so oft wie angegeben).
	for entry in String(args.get("events", "")).split(",", false):
		var parts := entry.split(":")
		var action := parts[0].split("/")
		for i in (int(parts[1]) if parts.size() > 1 else 1):
			grimoire.report(action[0], {"id": action[1]})
	if args.get("garden", "") == "demo":
		_plant_demo_garden()
	if args.has("name"):
		grimoire.witch_name = String(args["name"])
	if args.has("lang"):
		TranslationServer.set_locale(String(args["lang"]))
	if args.has("hour"):
		day_cycle.minutes = float(args["hour"]) * 60.0
	# day=5 springt in diese Nacht (Mondphase folgt daraus: 1 Neumond, 4 Halbmond, 8 Vollmond).
	if args.has("day"):
		day_cycle.day = int(args["day"])
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
	# spawn=res://scenes/world/blight_beetle.tscn@400,600 setzt eine Szene in den Ort.
	for entry in String(args.get("spawn", "")).split(";", false):
		var parts := entry.split("@")
		var node: Node2D = load(parts[0]).instantiate()
		main.level.objects.add_child(node)
		var xy := parts[1].split(",")
		node.global_position = Vector2(float(xy[0]), float(xy[1]))
		# freeze=0.3 hält einen Käfer im Innehalten vor dem Anlauf fest, mit so
		# vielen Sekunden Rest (unter 0.2 steht die Spur fest und leuchtet auf).
		if args.has("freeze") and node.has_method("take_hit"):
			await process_frame
			node._player = main.player
			node._notice(0.45, main.player.global_position - node.global_position)
			node._timer = float(args["freeze"])
			node.set_physics_process(false)
	# map=1 zeigt den ganzen Ort auf einmal (Überblick für Leveldesign),
	# ohne HUD-Rücksicht; die Nachtfärbung bleibt.
	if args.has("map"):
		var rect: Rect2 = main.level.pixel_rect()
		var cam: Camera2D = main.player.camera
		for side in ["limit_left", "limit_top", "limit_right", "limit_bottom"]:
			cam.set(side, 10000000 if side in ["limit_right", "limit_bottom"] else -10000000)
		var view := Vector2(main.get_viewport().get_visible_rect().size)
		var fit := minf(view.x / rect.size.x, view.y / rect.size.y)
		cam.zoom = Vector2(fit, fit)
		main.player.global_position = rect.get_center()
		cam.position_smoothing_enabled = false
	main.player.camera.reset_smoothing()
	if args.has("book"):
		grimoire.has_book = true
		var book := root.get_tree().get_first_node_in_group("grimoire_book")
		book.open(String(args["book"]))
	if args.has("message"):
		root.get_node("Messages").post(TranslationServer.translate(String(args["message"])))
	# interact=Objects/NoticeBoard tut, was E an diesem Objekt im Ort tut.
	if args.has("interact"):
		var target: Node = main.level.get_node(String(args["interact"]))
		target._on_interactable_interacted(main.player)
	# press=inventory,ui_cancel drückt Tasten (Aktionen) nacheinander.
	for action in String(args.get("press", "")).split(",", false):
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			root.push_input(event)
			await process_frame
	# call=UI/InventoryWindow:_on_slot_hovered:3 ruft eine Methode an einem
	# Node unter main.tscn auf (Zahlen werden als Zahl übergeben).
	for entry in String(args.get("call", "")).split(";", false):
		var parts := entry.split(":")
		var call_args := []
		for value in parts.slice(2):
			call_args.append(int(value) if value.is_valid_int() else value)
		main.get_node(parts[0]).callv(parts[1], call_args)
	# say=SCHLÜSSEL zeigt eine Zeile in der Dialogbox (Sprecher: Nachtwächter).
	if args.has("say"):
		var lines: Array[String] = [String(args["say"])]
		root.get_tree().get_first_node_in_group("dialogue_box").show_lines("NPC_WATCHMAN", lines)
	if args.has("brew"):
		root.get_tree().get_first_node_in_group("brew_window").open()
	await _shoot(args)


func _shoot(args: Dictionary) -> void:
	for i in int(args.get("frames", 60)):
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var out := String(args.get("out", "user://screenshot.png"))
	image.save_png(out)
	print("Screenshot gespeichert: %s (%s)" % [out, image.get_size()])
	quit()


## Zwei Reihen Beete mit allen Pflanzen in verschiedenen Stufen, dort wo im
## Garten die ersten Beete liegen.
func _plant_demo_garden() -> void:
	var garden := root.get_node("Garden")
	var plants := ["mandrake", "ghost_fern", "lantern_berry", "nightshade", "blood_rose", "moon_chalice"]
	for i in plants.size():
		for row in 2:
			var cell: Vector2i = garden.cell_at(Vector2(560 + 32 * i, 304 + 64 * row))
			garden.add_bed(cell)
			garden.plant_seed(cell, plants[i])
			for stage in (row * 2 + 1):
				garden.grow(cell)


func _args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		result[parts[0]] = parts[1] if parts.size() > 1 else ""
	return result
