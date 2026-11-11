## Startet alle Tests in `tests/` (Dateien `test_*.gd`), headless:
##   godot --headless --script res://tests/run_tests.gd
## Nur eine Datei:            … -- test_smoke
## Exit-Code 0 = alles grün, 1 = mindestens ein Fehler.
##
## Ein Test ist auch dann rot, wenn währenddessen irgendetwas als Fehler oder
## Warnung protokolliert wird (Skriptfehler, push_error, push_warning,
## Engine-Fehler), außer der Test hat es mit expect_error() angekündigt.
extends SceneTree

const TEST_DIR := "res://tests"
const ErrorCatcher := preload("res://tests/helpers/error_catcher.gd")


func _initialize() -> void:
	# Erst einen Frame warten, damit die Autoloads (Inventory, Moon …) bereit sind.
	await process_frame
	var only := OS.get_cmdline_user_args()
	var passed := 0
	var failed := 0
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)

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
		suite.catcher = catcher
		print("\n%s" % file_name)
		for method in suite.get_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			catcher.take()
			suite.before_each()
			await suite.call(test_name)
			await suite.after_each()
			var failures: PackedStringArray = suite.take_failures()
			var logged := catcher.take()
			if suite.take_warnings_allowed():
				logged = logged.filter(func(entry: Dictionary) -> bool: return not entry["warning"])
			failures.append_array(_unexpected(logged, suite.take_expected_errors()))
			if failures.is_empty():
				passed += 1
				print("  ✓ %s" % test_name)
			else:
				failed += 1
				print("  ✗ %s" % test_name)
				for line in failures:
					print("      %s" % line)

	OS.remove_logger(catcher)
	print("\n%d bestanden, %d fehlgeschlagen" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Vergleicht, was protokolliert wurde, mit dem, was der Test angekündigt hat.
## Rot ist beides: eine Meldung, die niemand erwartet hat, und eine erwartete,
## die ausblieb (dann prüft der Test nicht mehr, was er behauptet).
func _unexpected(entries: Array[Dictionary], expected: PackedStringArray) -> PackedStringArray:
	var problems: PackedStringArray = []
	var seen := {}
	for entry in entries:
		var announced := false
		for part in expected:
			if String(entry["text"]).contains(part):
				announced = true
				seen[part] = true
		if not announced:
			problems.append("Unerwartet protokolliert: %s" % ErrorCatcher.describe(entry))
	for part in expected:
		if not seen.has(part):
			problems.append("Angekündigte Meldung blieb aus: „%s“" % part)
	return problems


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			files.append(TEST_DIR.path_join(file))
	files.sort()
	return files
