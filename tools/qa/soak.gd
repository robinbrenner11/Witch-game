extends SceneTree

## Dauerlauf: Neues Spiel, dann jeden Ort laden und dort eine Weile laufen
## lassen (Käfer, NPCs, Wildwuchs, Uhr). Fehler erscheinen im Protokoll als
## SCRIPT ERROR / ERROR. Läuft headless:
##   godot --headless --script res://tools/qa/soak.gd
## Optional: -- frames=300 hour=22 day=8 (Frames pro Ort, Startzeit, Nacht für die Mondphase)

const LEVELS := [
	"res://scenes/world/shelter.tscn", "res://scenes/world/garden.tscn",
	"res://scenes/world/forest.tscn",
	"res://scenes/world/village.tscn", "res://scenes/world/lakewood.tscn",
	"res://scenes/world/waterfall_cave.tscn", "res://scenes/world/swamp.tscn",
	"res://scenes/world/tower_ruin.tscn",
]


func _initialize() -> void:
	await process_frame
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else ""
	root.get_node("SaveGame").new_game()
	var day_cycle := root.get_node("DayCycle")
	day_cycle.minutes = float(args.get("hour", 22)) * 60.0
	day_cycle.day = int(args.get("day", 1))
	Engine.time_scale = 4.0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for path in LEVELS:
		main._load_level(path)
		print("SOAK Ort: %s (%02d:%02d)" % [path.get_file(), day_cycle.hour(), day_cycle.minute()])
		for i in int(args.get("frames", 300)):
			await physics_frame
	print("SOAK fertig, Hexe lebt: %s" % str(main.player.get_node("Vitals").health > 0))
	quit()
