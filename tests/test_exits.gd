## Ausgänge: Jeder Ausgang eines Ortes führt in eine Szene, die es gibt, und
## dort zu einem Ausgang, der zurückführt. Sonst landet die Hexe nach einem
## Umbau (z. B. Seewald v2 ersetzt den alten) im Nichts oder an der falschen Stelle.
extends TestCase

const WORLD := "res://scenes/world/"


func _levels() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at(WORLD):
		if file.ends_with(".tscn"):
			paths.append(WORLD + file)
	return paths


func _exit_names(scene_path: String) -> Array[String]:
	var root := (load(scene_path) as PackedScene).instantiate()
	var names: Array[String] = []
	for exit in root.find_children("*", "Exit", true, false):
		names.append(String(exit.name))
	root.free()
	return names


func test_every_exit_leads_somewhere_and_back() -> void:
	for path in _levels():
		var root := (load(path) as PackedScene).instantiate()
		if not root is Level:
			root.free()
			continue
		for exit: Exit in root.find_children("*", "Exit", true, false):
			var label := "%s/%s" % [path.get_file(), exit.name]
			check(ResourceLoader.exists(exit.target_scene), "%s: Ziel %s gibt es" % [label, exit.target_scene])
			if not ResourceLoader.exists(exit.target_scene):
				continue
			var target_root := (load(exit.target_scene) as PackedScene).instantiate()
			var back := target_root.find_child(exit.target_exit, true, false) as Exit
			check(back != null, "%s: Ausgang %s im Ziel gibt es" % [label, exit.target_exit])
			if back:
				check_eq(back.target_scene, path, "%s: %s führt zurück" % [label, exit.target_exit])
				check_eq(back.target_exit, String(exit.name), "%s: Rückweg kommt hier heraus" % label)
			target_root.free()
		root.free()


func test_old_lakewood_is_gone() -> void:
	check(not ResourceLoader.exists(WORLD + "lakewood_v2.tscn"), "Seewald v2 heißt jetzt lakewood.tscn")
	var lakewood_exits := _exit_names(WORLD + "lakewood.tscn")
	for name in ["ToCave", "ToSwamp", "ToGarden", "ToForest", "ToVillage"]:
		check(lakewood_exits.has(name), "Seewald hat %s" % name)
