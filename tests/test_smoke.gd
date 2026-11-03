## Grundprüfung: Lädt alles im Projekt und prüft, dass Daten und Texte zusammenpassen.
## Fängt die häufigsten Fehler nach Umbauten ab (kaputte Pfade, vergessene Texte, Tippfehler in IDs).
extends TestCase

const SKIP_DIRS := ["res://tests"]


func test_all_scripts_load() -> void:
	for path in _project_files(["gd"]):
		var script := load(path) as Script
		check(script != null and script.can_instantiate(), "Script lädt nicht: %s" % path)


func test_all_resources_load() -> void:
	for path in _project_files(["tres"]):
		check(load(path) != null, "Ressource lädt nicht: %s" % path)


func test_all_scenes_instantiate() -> void:
	for path in _project_files(["tscn"]):
		var packed := load(path) as PackedScene
		if packed == null:
			check(false, "Szene lädt nicht: %s" % path)
			continue
		var node := packed.instantiate()
		check(node != null, "Szene lässt sich nicht instanziieren: %s" % path)
		if node != null:
			node.free()


## Godot meldet kaputte Verweise nur als Fehlertext und lädt trotzdem weiter.
## Deshalb hier selbst nachsehen, ob jede Datei, auf die Szenen und Ressourcen zeigen, existiert.
func test_references_exist() -> void:
	var regex := RegEx.create_from_string('path="(res://[^"]+)"')
	for path in _project_files(["tscn", "tres"]):
		var text := FileAccess.get_file_as_string(path)
		for match in regex.search_all(text):
			var target := match.get_string(1)
			check(FileAccess.file_exists(target), "%s zeigt auf fehlende Datei %s" % [path, target])


func test_texts_complete() -> void:
	var seen := {}
	for row in _text_rows():
		var key: String = row[0]
		check(not seen.has(key), "Text-Schlüssel doppelt: %s" % key)
		seen[key] = true
		check(row.size() >= 3 and row[1].strip_edges() != "", "Englischer Text fehlt: %s" % key)
		check(row.size() >= 3 and row[2].strip_edges() != "", "Deutscher Text fehlt: %s" % key)


func test_items_consistent() -> void:
	var keys := _text_keys()
	for path in TestCase.files_under("res://data/items", ["tres"]):
		var item = load(path)
		if item == null:
			continue  # meldet schon test_all_resources_load
		check_eq(item.id, path.get_file().get_basename(), "Item-ID passt nicht zum Dateinamen")
		check(item.icon != null, "Item ohne Icon: %s" % item.id)
		check(keys.has(item.display_name), "Item-Name fehlt in texts.csv: %s (%s)" % [item.id, item.display_name])
		if item.description != "":
			check(keys.has(item.description), "Item-Beschreibung fehlt in texts.csv: %s" % item.id)


func test_recipes_use_existing_items() -> void:
	var keys := _text_keys()
	var seen := {}
	for path in TestCase.files_under("res://data/recipes", ["tres"]):
		var recipe = load(path)
		if recipe == null:
			continue
		check(_item_exists(recipe.result_item_id), "Rezept-Ergebnis gibt es nicht: %s" % path)
		for ingredient in recipe.ingredients:
			check(_item_exists(ingredient), "Zutat gibt es nicht: %s in %s" % [ingredient, path])
		if recipe.margin_note_key != "":
			check(keys.has(recipe.margin_note_key), "Rezept-Notiz fehlt in texts.csv: %s" % recipe.margin_note_key)
		# Zwei Rezepte mit denselben Zutaten wären mehrdeutig.
		var sorted_ingredients: Array = recipe.ingredients.duplicate()
		sorted_ingredients.sort()
		var combo := ",".join(PackedStringArray(sorted_ingredients))
		check(not seen.has(combo), "Zwei Rezepte mit denselben Zutaten: %s" % combo)
		seen[combo] = true


# --- Hilfen ---------------------------------------------------------------

func _project_files(extensions: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for path in TestCase.files_under("res://", extensions):
		var skip := false
		for dir in SKIP_DIRS:
			if path.begins_with(dir):
				skip = true
		if not skip:
			result.append(path)
	return result


func _item_exists(id: String) -> bool:
	return ResourceLoader.exists("res://data/items/%s.tres" % id)


func _text_rows() -> Array:
	var rows := []
	var file := FileAccess.open("res://data/translations/texts.csv", FileAccess.READ)
	if file == null:
		check(false, "texts.csv nicht gefunden")
		return rows
	file.get_csv_line()  # Kopfzeile
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 0 or row[0].strip_edges() == "":
			continue
		rows.append(row)
	return rows


func _text_keys() -> Dictionary:
	var keys := {}
	for row in _text_rows():
		keys[row[0]] = true
	return keys
