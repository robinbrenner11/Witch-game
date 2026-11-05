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


## null, wenn es die Form nicht gibt.
static func from_id(form_id: String) -> DigitalisForm:
	var path := DIRECTORY % form_id
	return load(path) if form_id != "" and ResourceLoader.exists(path) else null


## Die Form in dieser Stufe. Fehlt die Datei für die Stufe, gilt die
## nächstniedrigere, am Ende die Grundform.
static func at_level(form_id: String, level: int) -> DigitalisForm:
	for stage in range(level, 1, -1):
		var path := UPGRADE_DIRECTORY % [form_id, stage]
		if ResourceLoader.exists(path):
			return load(path)
	return from_id(form_id)
