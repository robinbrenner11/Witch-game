## Fängt alles ab, was Godot als Fehler oder Warnung protokolliert (Skriptfehler,
## push_error, push_warning, Engine-Fehler), damit der Testlauf und der
## Dauerlauf selbst merken, wenn etwas schiefgeht. Vorher fiel ein Skriptfehler
## nur auf, wenn jemand die Ausgabe las: Eine Funktion bricht bei einem Fehler
## einfach ab, und der Test lief grün weiter.
##
## Benutzung:
##   var catcher := preload("res://tests/helpers/error_catcher.gd").new()
##   OS.add_logger(catcher)
##   … etwas tun …
##   for entry in catcher.take(): …
extends Logger

const TYPE_NAMES := {
	ERROR_TYPE_ERROR: "Fehler", ERROR_TYPE_WARNING: "Warnung",
	ERROR_TYPE_SCRIPT: "Skriptfehler", ERROR_TYPE_SHADER: "Shaderfehler",
}

# Godot ruft den Logger auch aus anderen Threads auf (Laden, Audio).
var _mutex := Mutex.new()
var _entries: Array[Dictionary] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var where := "%s:%d (%s)" % [file, line, function]
	# Bei push_error und Skriptfehlern zeigt file auf den C++-Code der Engine;
	# die Stelle im Spiel steht im Backtrace.
	for backtrace in script_backtraces:
		if backtrace.get_frame_count() > 0:
			where = "%s:%d (%s)" % [backtrace.get_frame_file(0), backtrace.get_frame_line(0), backtrace.get_frame_function(0)]
			break
	var entry := {
		"type": error_type,
		"warning": error_type == ERROR_TYPE_WARNING,
		# rationale ist die eigentliche Meldung, code die Bedingung oder der Text von push_error.
		"text": ("%s %s" % [rationale, code]).strip_edges(),
		"where": where,
	}
	_mutex.lock()
	_entries.append(entry)
	_mutex.unlock()


## Gibt alles seit dem letzten Aufruf Gesammelte heraus und leert die Liste.
func take() -> Array[Dictionary]:
	_mutex.lock()
	var result := _entries
	_entries = []
	_mutex.unlock()
	return result


static func describe(entry: Dictionary) -> String:
	return "%s: %s [%s]" % [TYPE_NAMES.get(entry["type"], "Fehler"), entry["text"], entry["where"]]
