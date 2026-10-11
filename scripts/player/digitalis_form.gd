class_name DigitalisForm
extends Resource

## Eine Form von Digitalis (Stab, Sichel, später Dornenpeitsche, Wurzelhammer).
## Jede Form ist eine Datei in data/digitalis/<id>.tres mit je einem leichten
## (Linksklick) und einem starken Angriff (Rechtsklick). Neue Formen brauchen
## so nur eine neue Datei; neuer Code nur, wenn eine ganz neue Angriffsart
## dazukommt (siehe AttackData.Kind).

const DIRECTORY := "res://data/digitalis/%s.tres"

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
