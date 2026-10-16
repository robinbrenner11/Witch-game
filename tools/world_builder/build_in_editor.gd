@tool
extends EditorScript

## Baut alle Orte aus ihren Bauplänen (tools/world_builder/plans/).
## So geht's: diese Datei im Skript-Editor öffnen, dann Datei → Ausführen
## (Strg+Umschalt+X). Ist die Szene eines Orts gerade offen, fragt Godot
## danach, ob sie neu geladen werden soll: mit Ja bestätigen.

const PLANS := "res://tools/world_builder/plans/"


func _run() -> void:
	for plan in DirAccess.get_directories_at(PLANS):
		var builder := WorldBuilder.new()
		var error := builder.build(PLANS + plan)
		for line in builder.report:
			print("  ", line)
		print("%s: %s" % [plan, "fertig" if error == OK else "Fehler %d" % error])
	EditorInterface.get_resource_filesystem().scan()
