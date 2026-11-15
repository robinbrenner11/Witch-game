## Startet alle Tests in `tests/` (Dateien `test_*.gd`), headless:
##   godot --headless --script res://tests/run_tests.gd
## Nur eine Datei:            … -- test_smoke
## Exit-Code 0 = alles grün, 1 = mindestens ein Fehler.
extends SceneTree

const TEST_DIR := "res://tests"


func _initialize() -> void:
	# Erst einen Frame warten, damit die Autoloads (Inventory, Moon …) bereit sind.
	await process_frame
	var only := OS.get_cmdline_user_args()
	var passed := 0
	var failed := 0

	for file in _test_files():
		var file_name := file.get_file().get_basename()
		if not only.is_empty() and not file_name in only:
			continue
		var script := load(file) as GDScript
		if script == null or not script.can_instantiate():
			print("✗ %s lässt sich nicht laden" % file_name)
			failed += 1
			continue
		var suite = script.new()
		if not suite is TestCase:
			print("✗ %s erbt nicht von TestCase" % file_name)
			failed += 1
			continue
		suite.tree = self
		print("\n%s" % file_name)
		for method in suite.get_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			suite.before_each()
			await suite.call(test_name)
			await suite.after_each()
			var failures: PackedStringArray = suite.take_failures()
			if failures.is_empty():
				passed += 1
				print("  ✓ %s" % test_name)
			else:
				failed += 1
				print("  ✗ %s" % test_name)
				for line in failures:
					print("      %s" % line)

	print("\n%d bestanden, %d fehlgeschlagen" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			files.append(TEST_DIR.path_join(file))
	files.sort()
	return files
