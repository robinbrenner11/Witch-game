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


func reset() -> void:
	_flags.clear()


func get_save_data() -> Dictionary:
	return {"flags": _flags.keys()}


func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	var flags: Variant = data.get("flags", [])
	if not flags is Array:
		push_warning("WorldState: Flags im Spielstand sind keine Liste")
		return
	for flag in flags:
		if flag is String and flag != "":
			_flags[flag] = true
