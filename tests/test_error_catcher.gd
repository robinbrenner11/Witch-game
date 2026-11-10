## Der Testlauf merkt selbst, wenn etwas als Fehler oder Warnung protokolliert
## wird (tests/helpers/error_catcher.gd). Hier wird geprüft, dass der Fänger
## Skriptfehler, push_error und push_warning wirklich sieht. Die Meldungen
## sind mit expect_error() angekündigt, sonst wäre dieser Test selbst rot.
extends TestCase

const ErrorCatcher := preload("res://tests/helpers/error_catcher.gd")

var _catcher: Logger


func before_each() -> void:
	_catcher = ErrorCatcher.new()
	OS.add_logger(_catcher)


func after_each() -> void:
	OS.remove_logger(_catcher)


func test_catches_push_error_and_warning() -> void:
	expect_error("Probe-Fehler")
	expect_error("Probe-Warnung")
	push_error("Probe-Fehler")
	push_warning("Probe-Warnung")
	var entries: Array[Dictionary] = _catcher.take()
	check_eq(entries.size(), 2, "Beides gefangen")
	if entries.size() == 2:
		check(not entries[0]["warning"] and String(entries[0]["text"]).contains("Probe-Fehler"), "Fehler mit Text")
		check(entries[1]["warning"], "Warnung als Warnung erkannt")
		check(String(entries[0]["where"]).contains("test_error_catcher.gd"), "Stelle im Spielcode: " + String(entries[0]["where"]))


## Ein Skriptfehler bricht in GDScript nur die laufende Funktion ab. Ohne den
## Fänger liefe ein Test danach einfach grün weiter.
func test_catches_script_errors() -> void:
	expect_error("Nonexistent function")
	_call_missing_method()
	var entries: Array[Dictionary] = _catcher.take()
	check_eq(entries.size(), 1, "Skriptfehler gefangen")
	if entries.size() == 1:
		check_eq(entries[0]["type"], Logger.ERROR_TYPE_SCRIPT, "Als Skriptfehler erkannt")


func _call_missing_method() -> void:
	var thing: Variant = RefCounted.new()
	thing.gibt_es_nicht()
