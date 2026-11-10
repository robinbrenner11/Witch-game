class_name DigitalisForm
extends Resource

## Eine Form von Digitalis (Stab, Sichel, später Dornenpeitsche, Wurzelhammer).
## Jede Form ist eine Datei in data/digitalis/<id>.tres mit je einem leichten
## (Linksklick) und einem starken Angriff (Rechtsklick). Neue Formen brauchen
## so nur eine neue Datei; neuer Code nur, wenn eine ganz neue Angriffsart
## dazukommt (siehe AttackData.Kind).

const DIRECTORY := "res://data/digitalis/%s.tres"
# Höhere Stufen (Upgrades bei Gnarl) sind eigene Dateien, z. B.
# upgrades/staff_2.tres: dieselbe Form mit anderen Werten. Balancing = Zahlen.
const UPGRADE_DIRECTORY := "res://data/digitalis/upgrades/%s_%d.tres"

@export var id: String = ""
# Schlüssel in data/translations/texts.csv (DIGITALIS_<ID>).
@export var display_name: String = ""
# Bild in der Kampfleiste. Leer = Platzhalter-Zeichnung (siehe CombatBar).
@export var icon: Texture2D
@export var light: AttackData
@export var heavy: AttackData


# Höher wird keine Stufe gesucht (auch nicht aus einem kaputten Spielstand).
const MAX_LEVEL := 9

# "id" bzw. "id/stufe" -> DigitalisForm (oder null), siehe ItemData._cache.
static var _cache: Dictionary = {}


## null, wenn es die Form nicht gibt.
static func from_id(form_id: String) -> DigitalisForm:
	if form_id == "":
		return null
	if not _cache.has(form_id):
		var path := DIRECTORY % form_id
		_cache[form_id] = load(path) if ResourceLoader.exists(path) else null
	return _cache[form_id]


## Die Form in dieser Stufe. Fehlt die Datei für die Stufe, gilt die
## nächstniedrigere, am Ende die Grundform.
static func at_level(form_id: String, level: int) -> DigitalisForm:
	level = clampi(level, 1, MAX_LEVEL)
	var key := "%s/%d" % [form_id, level]
	if not _cache.has(key):
		var form := from_id(form_id)
		for stage in range(level, 1, -1):
			var path := UPGRADE_DIRECTORY % [form_id, stage]
			if ResourceLoader.exists(path):
				form = load(path)
				break
		_cache[key] = form
	return _cache[key]
