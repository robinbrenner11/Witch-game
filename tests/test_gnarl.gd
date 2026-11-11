## Gnarl (Schritt 7, Teil 1): sitzt im tiefen Wald, will einen Heiltrank und
## zieht danach mit der nächsten Nacht in die Werkstatt im Dorf.
## Dazu die Bausteine: Flags an Routine-Blöcken, Flags ab der nächsten Nacht,
## Gaben ohne Gegenleistung im Tausch.
extends TestCase

const GNARL := preload("res://data/npcs/gnarl.tres")
const HELP := preload("res://data/trades/gnarl/a_help_mending.tres")
# Mitten in der Nacht (22 Uhr), damit ein Block aktiv ist.
const NIGHT_TIME := 22 * 60.0


func before_each() -> void:
	WorldState.reset()
	Inventory.reset()
	Grimoire.reset()
	DayCycle.reset()


func test_lives_in_forest_until_moved() -> void:
	var entry := GNARL.entry_at(NIGHT_TIME)
	check(entry != null and entry.level == "Forest", "Anfangs im Wald")
	check_eq(entry.spot if entry else "", "GnarlCamp", "Spot im Wald")
	WorldState.set_flag("gnarl_moved")
	entry = GNARL.entry_at(NIGHT_TIME)
	check(entry != null and entry.level == "Village", "Nach dem Umzug im Dorf")
	check_eq(entry.spot if entry else "", "Workshop", "Spot an der Werkstatt")
	check(GNARL.entry_at(12 * 60.0) == null, "Tagsüber nicht da")


func test_flag_next_night() -> void:
	WorldState.set_flag_next_night("test_flag")
	check(not WorldState.has_flag("test_flag"), "Noch nicht gesetzt")
	check(WorldState.is_pending("test_flag"), "Vorgemerkt")
	var saved := WorldState.get_save_data()
	WorldState.reset()
	WorldState.load_save_data(saved)
	check(WorldState.is_pending("test_flag"), "Vormerkung übersteht Speichern und Laden")
	DayCycle.advance_day()
	check(WorldState.has_flag("test_flag"), "Mit der nächsten Nacht gesetzt")
	check(not WorldState.is_pending("test_flag"), "Vormerkung weg")
	# Alter Spielstand ohne Vormerkungen lädt ohne Fehler.
	WorldState.load_save_data({"flags": ["a"]})
	check(WorldState.has_flag("a") and not WorldState.is_pending("test_flag"), "Alter Spielstand")


func test_help_offer() -> void:
	check(not HELP.is_offered("gnarl"), "Ohne Kennenlernen keine Gabe")
	WorldState.set_flag("met_gnarl")
	check(HELP.is_offered("gnarl"), "Nach dem Kennenlernen angeboten")
	check_eq(HELP.label(), tr("TRADE_GIVE") % [1, Inventory.display_name_for("potion_mending")], "Text der Gabe")
	check(not HELP.trade("gnarl"), "Ohne Heiltrank geht es nicht")
	check(not WorldState.has_flag("gnarl_helped"), "Ohne Heiltrank nicht geholfen")
	Inventory.add("potion_mending")
	check(HELP.trade("gnarl"), "Mit Heiltrank klappt es")
	check_eq(Inventory.count("potion_mending"), 0, "Heiltrank ist weg")
	check(WorldState.has_flag("gnarl_helped"), "Geholfen")
	check(WorldState.is_pending("gnarl_moved"), "Umzug zur nächsten Nacht vorgemerkt")
	check(not WorldState.has_flag("gnarl_moved"), "Noch nicht umgezogen")
	check(not HELP.is_offered("gnarl"), "Danach nicht mehr angeboten")
	DayCycle.advance_day()
	check(WorldState.has_flag("gnarl_moved"), "In der nächsten Nacht umgezogen")


func test_dialogue_order() -> void:
	check_eq(_pick(""), "first_meeting", "Zuerst das Kennenlernen")
	WorldState.set_flag("dlg_gnarl_first_meeting")
	WorldState.set_flag("met_gnarl")
	check_eq(_pick(""), "waiting", "Dann wartet er auf den Heiltrank")
	WorldState.set_flag("gnarl_helped")
	check_eq(_pick(""), "helped", "Dank nach der Hilfe")
	WorldState.set_flag("dlg_gnarl_helped")
	check_eq(_pick(""), "packing", "Er packt")
	WorldState.set_flag("gnarl_moved")
	check(_pick("workshop").begins_with("workshop_"), "In der Werkstatt")


func test_scenes_have_spots() -> void:
	var forest := (load("res://scenes/world/forest.tscn") as PackedScene).instantiate()
	check(forest.get_node_or_null("Spots/GnarlCamp") != null, "Spot im Wald")
	check(forest.get_node_or_null("Objects/Gnarl") is Npc, "Gnarl im Wald")
	forest.free()
	var village := (load("res://scenes/world/village.tscn") as PackedScene).instantiate()
	check(village.get_node_or_null("Spots/Workshop") != null, "Spot an der Werkstatt")
	check(village.get_node_or_null("Objects/Gnarl") is Npc, "Gnarl im Dorf")
	check(village.get_node_or_null("Objects/GnarlWorkshop") != null, "Werkstatt-Laterne")
	var lit_by_gnarl: Array = village.find_children("*", "Node2D", true, false).filter(
			func(n: Node) -> bool: return n is GrayboxBuilding and n.lit_flag == "gnarl_moved")
	check(lit_by_gnarl.size() == 1 and lit_by_gnarl[0].name == "Workshop", "Nur die Werkstatt leuchtet, wenn Gnarl einzieht")
	village.free()


## Die Spots dürfen nicht in einer Wand, einem Baum o. Ä. liegen, sonst steht
## Gnarl darin fest. Dazu den Ort wirklich in den Baum hängen und die Physik fragen.
func test_spots_are_free() -> void:
	for pair in [["res://scenes/world/forest.tscn", "Spots/GnarlCamp"],
			["res://scenes/world/village.tscn", "Spots/Workshop"]]:
		var level := (load(pair[0]) as PackedScene).instantiate() as Node2D
		tree.root.add_child(level)
		await tree.physics_frame
		await tree.physics_frame
		var spot := level.get_node(pair[1]) as Node2D
		var query := PhysicsShapeQueryParameters2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(14, 8)
		query.shape = shape
		query.transform = Transform2D(0, spot.global_position + Vector2(0, -3))
		query.collision_mask = 9
		var hits := level.get_world_2d().direct_space_state.intersect_shape(query)
		hits = hits.filter(func(hit: Dictionary) -> bool: return not hit.collider is Npc)
		check(hits.is_empty(), "%s in %s ist zugestellt: %s" % [pair[1], pair[0].get_file(),
				", ".join(hits.map(func(hit: Dictionary) -> String: return str(hit.collider.get_path())))])
		level.queue_free()
		await tree.process_frame


## Höchstens 3 Zeilen pro Seite der Dialogbox, auf Englisch und Deutsch.
func test_lines_fit() -> void:
	var box := (load("res://scenes/ui/dialogue_box.tscn") as PackedScene).instantiate() as DialogueBox
	tree.root.add_child(box)
	await tree.process_frame
	var keys: Array[String] = []
	for dialogue in DialogueData.all_for("gnarl"):
		keys.append_array(dialogue.lines)
	var old_locale := TranslationServer.get_locale()
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for key in keys:
			box.text_label.text = tr(key)
			box.text_label.visible_characters = -1
			check(box.text_label.get_line_count() <= 3, "%s (%s) hat %d Zeilen" % [key, locale, box.text_label.get_line_count()])
	TranslationServer.set_locale(old_locale)
	box.queue_free()
	await tree.process_frame


func _pick(topic: String) -> String:
	var dialogue := DialogueData.pick("gnarl", topic)
	return dialogue.id if dialogue else ""


## Der Nachtwächter weist auf die Kerze im Wald hin, solange man Gnarl nicht
## kennt, und bemerkt später das Licht in der Werkstatt.
func test_watchman_points_to_gnarl() -> void:
	WorldState.set_flag("met_watchman")
	WorldState.set_flag("dlg_watchman_first_meeting")
	# Gerüchte über Rezepte haben Vorrang; hier sind sie schon erzählt.
	for rumor in ["rumor_mending", "rumor_ember", "rumor_growth"]:
		WorldState.set_flag("dlg_watchman_" + rumor)
	var rumor := DialogueData.pick("watchman", "rumor")
	check(rumor != null and rumor.id == "rumor_gnarl", "Gerücht über die Kerze im Wald")
	WorldState.set_flag("met_gnarl")
	rumor = DialogueData.pick("watchman", "rumor")
	check(rumor == null or rumor.id != "rumor_gnarl", "Kein Gerücht mehr, wenn man Gnarl kennt")
	WorldState.set_flag("gnarl_moved")
	var line := DialogueData.pick("watchman", "")
	check(line != null and line.id == "workshop_light", "Wächter bemerkt das Licht in der Werkstatt")
