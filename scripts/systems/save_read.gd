class_name SaveRead
extends RefCounted

## Liest Werte aus einem geladenen Spielstand, ohne über falsche Typen zu
## stolpern. Ein Spielstand kommt als JSON von der Platte: Dort kann an jeder
## Stelle etwas anderes stehen als erwartet (älteres Format, von Hand
## bearbeitet, beschädigt). GDScript bricht bei int([]) oder String(5.0) die
## laufende Funktion mit einem Skriptfehler ab; ein System wäre dann halb
## geladen. Deshalb gehen alle load_save_data() über diese Funktionen:
## Passt der Typ nicht, gilt der Ersatzwert.
##
## Abgesichert durch tests/test_save_fuzz.gd.

# Größer können ganze Zahlen in JSON (Kommazahlen) nicht exakt sein; was
# darüber liegt, ist kein sinnvoller Spielwert.
const MAX_NUMBER := 9.0e15


static func as_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float and absf(value) <= MAX_NUMBER:
		return int(value)
	return fallback


static func as_float(value: Variant, fallback: float = 0.0) -> float:
	if (value is float or value is int) and absf(value) <= MAX_NUMBER:
		return float(value)
	return fallback


static func as_string(value: Variant, fallback: String = "") -> String:
	return value if value is String else fallback


static func as_bool(value: Variant, fallback: bool = false) -> bool:
	return value if value is bool else fallback


static func as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func as_array(value: Variant) -> Array:
	return value if value is Array else []


## Die Strings aus einer Liste: ohne leere, ohne doppelte, ohne alles andere.
static func strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry: Variant in as_array(value):
		if entry is String and entry != "" and not result.has(entry):
			result.append(entry)
	return result


## Wie strings(), aber Wiederholungen bleiben (z. B. zweimal dieselbe Zutat
## im Kessel).
static func strings_with_repeats(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry: Variant in as_array(value):
		if entry is String and entry != "":
			result.append(entry)
	return result


## {Schlüssel: true} für jeden String-Schlüssel eines Dictionarys (so merken
## sich die Systeme „schon gesehen“, „schon abgeholt“ …).
static func flags(value: Variant) -> Dictionary:
	var result := {}
	for key: Variant in as_dict(value):
		if key is String and key != "":
			result[key] = true
	return result


## {Schlüssel: ganze Zahl} aus einem Dictionary; Einträge mit anderem Typ oder
## unter minimum fallen weg.
static func counts(value: Variant, minimum: int = 0) -> Dictionary:
	var result := {}
	var source := as_dict(value)
	for key: Variant in source:
		var n: Variant = source[key]
		if key is String and key != "" and (n is float or n is int) and absf(n) <= MAX_NUMBER and int(n) >= minimum:
			result[key] = int(n)
	return result
