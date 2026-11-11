extends Node

## Merker der Welt (Flags): Dinge, die einmal passiert sind und danach so
## bleiben, z. B. "Pforte entriegelt" oder "Nachtwächter kennengelernt".
## Wer etwas freischaltet, ruft set_flag(); Tore, Dialoge und NPCs fragen nur
## has_flag(). So müssen sie einander nicht kennen.
##
## Bewusst nicht im Grimoire: Das Buch hält den Fortschritt der Hexe (Seiten,
## Stufen), das hier ist der Zustand der Welt. Siehe docs/archiv/dorf_hub_plan.md,
## Abschnitt 5.2.

signal flag_changed(flag: String)

# Flag -> true. Ein Dictionary statt eines Arrays, weil has() dann sofort
# antwortet, egal wie viele Flags es einmal werden.
var _flags: Dictionary = {}
# Was heute Nacht schon war, z. B. "watchman/rumor" (höchstens ein Gerücht pro
# Nacht), als Zähler. Wird mit jeder neuen Nacht geleert. Gespeichert wird es
# zusammen mit der Nacht: Wer mitten in der Nacht über das Pausemenü speichert
# und fortsetzt, ist noch in derselben Nacht. Sonst gäbe es Mondwasser und
# begrenzte Tauschangebote noch einmal, und ein für die Nacht geöffnetes Gate
# (Blütennebel) wäre wieder zu, obwohl der Trank verbraucht ist.
var _tonight: Dictionary = {}
# Flags, die erst mit der nächsten Nacht gesetzt werden (gespeichert). Für
# Dinge, die „über Nacht“ passieren, z. B. ein NPC, der umzieht: So
# verschwindet er nicht vor den Augen der Hexe.
var _next_night: Array[String] = []


func _ready() -> void:
	DayCycle.day_passed.connect(func(_day: int) -> void: _on_new_night())


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


## Setzt das Flag erst, wenn die nächste Nacht beginnt.
func set_flag_next_night(flag: String) -> void:
	if flag != "" and not _flags.has(flag) and not _next_night.has(flag):
		_next_night.append(flag)


func is_pending(flag: String) -> bool:
	return _next_night.has(flag)


func _on_new_night() -> void:
	_tonight.clear()
	var pending := _next_night.duplicate()
	_next_night.clear()
	for flag in pending:
		set_flag(flag)


## Merkt sich bis zum Ende der Nacht, dass etwas passiert ist.
func mark_tonight(key: String) -> void:
	_tonight[key] = maxi(times_tonight(key), 1)


func did_tonight(key: String) -> bool:
	return _tonight.has(key)


## Zählt etwas für diese Nacht hoch, z. B. gereinigte Neumond-Käfer eines Ortes.
func add_tonight(key: String) -> void:
	_tonight[key] = times_tonight(key) + 1


func times_tonight(key: String) -> int:
	return int(_tonight.get(key, 0))


func reset() -> void:
	_flags.clear()
	_tonight.clear()
	_next_night.clear()


func get_save_data() -> Dictionary:
	return {
		"flags": _flags.keys(), "next_night": _next_night.duplicate(),
		"tonight": _tonight.duplicate(), "tonight_day": DayCycle.day,
	}


func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	_tonight.clear()
	_next_night.clear()
	var pending: Variant = data.get("next_night", [])
	if pending is Array:
		for flag in pending:
			if flag is String and flag != "":
				_next_night.append(flag)
	# Nur wenn der Stand aus genau dieser Nacht stammt (DayCycle ist beim
	# Laden schon dran gewesen, siehe SaveGame._apply).
	if SaveRead.as_int(data.get("tonight_day"), -1) == DayCycle.day:
		_tonight = SaveRead.counts(data.get("tonight"), 1)
	var flags: Variant = data.get("flags", [])
	if not flags is Array:
		push_warning("WorldState: Flags im Spielstand sind keine Liste")
		return
	for flag in flags:
		if flag is String and flag != "":
			_flags[flag] = true
