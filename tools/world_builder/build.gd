extends SceneTree

## Baut Orte aus ihren Bauplänen, ohne den Editor zu öffnen.
## Aufruf (im Projektordner):
##   godot --headless --script res://tools/world_builder/build.gd             (alle Pläne)
##   godot --headless --script res://tools/world_builder/build.gd -- seewald  (nur einer)
## Im Editor geht dasselbe mit build_in_editor.gd (Datei öffnen, Strg+Umschalt+X).

const PLANS := "res://tools/world_builder/plans/"


func _initialize() -> void:

	var wanted := OS.get_cmdline_user_args()
	var failed := false
	for plan in DirAccess.get_directories_at(PLANS):
		if not wanted.is_empty() and plan not in wanted:
			continue
		var builder := WorldBuilder.new()
		var error := builder.build(PLANS + plan)
		for line in builder.report:
			print("  ", line)
		print("%s: %s" % [plan, "fertig" if error == OK else "Fehler %d" % error])
		failed = failed or error != OK
	quit(1 if failed else 0)
