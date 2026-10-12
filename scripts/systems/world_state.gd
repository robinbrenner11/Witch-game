extends Node

## Merker der Welt (Flags): Dinge, die einmal passiert sind und danach so
## bleiben, z. B. "Pforte entriegelt" oder "Nachtwächter kennengelernt".
## Wer etwas freischaltet, ruft set_flag(); Tore, Dialoge und NPCs fragen nur
## has_flag(). So müssen sie einander nicht kennen.
##
## Bewusst nicht im Grimoire: Das Buch hält den Fortschritt der Hexe (Seiten,
## Stufen), das hier ist der Zustand der Welt. Siehe docs/design/dorf_hub_plan.md,
## Abschnitt 5.2.

signal flag_changed(flag: String)

# Flag -> true. Ein Dictionary statt eines Arrays, weil has() dann sofort
# antwortet, egal wie viele Flags es einmal werden.
var _flags: Dictionary = {}
# Was heute Nacht schon war, z. B. "watchman/rumor" (höchstens ein Gerücht pro
# Nacht). Wird mit jeder neuen Nacht geleert und nicht gespeichert:
# Gespeichert wird beim Schlafen, also zu Beginn einer Nacht, wenn es ohnehin
# leer ist. Speichert man mitten in der Nacht über das Pausemenü und lädt,
# kann sich höchstens etwas Nächtliches einmal wiederholen.
var _tonight: Dictionary = {}


func _ready() -> void:
	DayCycle.day_passed.connect(func(_day: int) -> void: _tonight.clear())


func set_flag(flag: String) -> void:
	if flag == "" or _flags.has(flag):
		return
	_flags[flag] = true
	flag_changed.emit(flag)


func has_flag(flag: String) -> bool:
	return _flags.has(flag)


## Sind alle diese Flags gesetzt? Eine leere Liste ist immer erfüllt.
func has_all(flags: Array[String]) -> bool:
	for flag in flags:
		if not _flags.has(flag):
			return false
	return true


## Ist keines dieser Flags gesetzt? Eine leere Liste ist immer erfüllt.
func has_none(flags: Array[String]) -> bool:
	for flag in flags:
		if _flags.has(flag):
			return false
	return true


## Merkt sich bis zum Ende der Nacht, dass etwas passiert ist.
func mark_tonight(key: String) -> void:
	_tonight[key] = true


func did_tonight(key: String) -> bool:
	return _tonight.has(key)


func reset() -> void:
	_flags.clear()
	_tonight.clear()


func get_save_data() -> Dictionary:
	return {"flags": _flags.keys()}


func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	_tonight.clear()
	var flags: Variant = data.get("flags", [])
	if not flags is Array:
		push_warning("WorldState: Flags im Spielstand sind keine Liste")
		return
	for flag in flags:
		if flag is String and flag != "":
			_flags[flag] = true
