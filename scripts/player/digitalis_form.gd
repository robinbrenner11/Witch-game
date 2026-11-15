class_name DigitalisForm
extends Resource

## Eine Form von Digitalis (Stab, Sichel, später Dornenpeitsche, Wurzelhammer).
## Jede Form ist eine Datei in data/digitalis/<id>.tres mit je einem leichten
## (Linksklick) und einem starken Angriff (Rechtsklick). Neue Formen brauchen
## so nur eine neue Datei; neuer Code nur, wenn eine ganz neue Angriffsart
## dazukommt (siehe AttackData.Kind).
##
## Upgrades (Gnarl): Jede höhere Stufe ist eine eigene, vollständige Datei
## <id>_<stufe>.tres mit derselben id, z. B. staff_2.tres. Balancing einer
## Stufe = Zahlen in ihrer Datei ändern. Welche Stufe die Hexe hat, weiß das
## Grimoire (upgrade_level).

const DIRECTORY := "res://data/digitalis/%s.tres"

@export var id: String = ""
# Schlüssel in data/translations/texts.csv (DIGITALIS_<ID>).
@export var display_name: String = ""
# Bild in der Kampfleiste. Leer = Platzhalter-Zeichnung (siehe CombatBar).
@export var icon: Texture2D
# Große Abbildung im Grimoire (1:1 aus der Vorlage, docs/art/ref_converter/
# convert_illustration.py). Leer = keine Abbildung.
@export var book_image: Texture2D
@export var light: AttackData
@export var heavy: AttackData
## Stufe dieser Datei (1 = ohne Upgrade).
@export var level: int = 1


## Die Form in dieser Stufe. Gibt es die Stufe nicht als Datei, die nächst-
## niedrigere. null, wenn es die Form gar nicht gibt.
static func from_id(form_id: String, at_level: int = 1) -> DigitalisForm:
	if form_id == "":
		return null
	for step in range(at_level, 1, -1):
		var upgraded := DIRECTORY % ("%s_%d" % [form_id, step])
		if ResourceLoader.exists(upgraded):
			return load(upgraded)
	var path := DIRECTORY % form_id
	return load(path) if ResourceLoader.exists(path) else null
