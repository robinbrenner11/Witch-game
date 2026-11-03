## Basis für alle Tests. Eine Testdatei erbt hiervon, jede Methode `test_…` ist ein Test.
## Warum kein Plugin wie GUT: Für unsere Prüfungen reichen ein paar Hilfsfunktionen,
## und so läuft alles mit einem nackten Godot ohne Zusatz-Installation.
class_name TestCase
extends RefCounted

## Der laufende SceneTree, falls ein Test Szenen instanziieren oder Frames abwarten muss.
var tree: SceneTree

var _failures: PackedStringArray = []


## Prüft eine Bedingung. Schlägt sie fehl, wird der Test rot, läuft aber weiter,
## damit man alle Fehler auf einmal sieht.
func check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s (ist: %s, erwartet: %s)" % [message, str(actual), str(expected)])


## Wird vor jedem Test aufgerufen. Bei Bedarf überschreiben (z. B. Autoload-Zustand zurücksetzen).
func before_each() -> void:
	pass


func take_failures() -> PackedStringArray:
	var result := _failures
	_failures = []
	return result


## Alle Dateien unter `root` mit einer der Endungen, ohne .godot und Git-Kram.
static func files_under(root: String, extensions: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir := DirAccess.open(root)
	if dir == null:
		return result
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		result.append_array(files_under(root.path_join(sub), extensions))
	for file in dir.get_files():
		if file.get_extension() in extensions:
			result.append(root.path_join(file))
	return result
