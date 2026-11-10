## Basis für alle Tests. Eine Testdatei erbt hiervon, jede Methode `test_…` ist ein Test.
## Warum kein Plugin wie GUT: Für unsere Prüfungen reichen ein paar Hilfsfunktionen,
## und so läuft alles mit einem nackten Godot ohne Zusatz-Installation.
class_name TestCase
extends RefCounted

## Der laufende SceneTree, falls ein Test Szenen instanziieren oder Frames abwarten muss.
var tree: SceneTree

## Der Fehler-Fänger des Testlaufs (tests/helpers/error_catcher.gd).
var catcher: Logger

var _failures: PackedStringArray = []
var _expected_errors: PackedStringArray = []
var _warnings_allowed := false


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


## Wird nach jedem Test aufgerufen (darf await nutzen), z. B. zum Aufräumen von
## Nodes, damit sie nicht in spätere Tests hineinwirken.
func after_each() -> void:
	pass


## Kündigt an, dass dieser Test absichtlich einen Fehler oder eine Warnung
## auslöst, deren Text `part` enthält (z. B. beim Laden eines kaputten
## Spielstands). Alles andere, was protokolliert wird, macht den Test rot.
func expect_error(part: String) -> void:
	_expected_errors.append(part)


func take_expected_errors() -> PackedStringArray:
	var result := _expected_errors
	_expected_errors = []
	return result


## In diesem Test sind Warnungen in Ordnung (z. B. wenn er absichtlich viele
## kaputte Daten lädt und die Systeme das melden). Fehler bleiben rot.
func allow_warnings() -> void:
	_warnings_allowed = true


func take_warnings_allowed() -> bool:
	var result := _warnings_allowed
	_warnings_allowed = false
	return result


## Alles, was seit dem letzten Aufruf (oder seit Testbeginn) protokolliert
## wurde. Was der Test hier abholt, wertet er selbst aus; der Testlauf meldet
## es nicht noch einmal.
func take_logged() -> Array[Dictionary]:
	return catcher.take() if catcher else ([] as Array[Dictionary])


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
