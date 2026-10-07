class_name ItemData
extends Resource

## Beschreibt ein Item als Datendatei in data/items/<id>.tres. Jedes Item im
## Spiel hat so eine Datei: Samen, Ernte, Tränke, später Kristalle, Werkzeuge …
## Neue Items brauchen so keinen neuen Code. Der Dateiname ist die ID.

# Wofür ein Item grundsätzlich taugt. Bestimmt z. B., was in den Kessel darf.
enum Type { SEED, INGREDIENT, POTION, TOOL, MISC }
# Wie ein Item benutzt wird. Getrunkenes wirkt auf die Hexe, Ausgegossenes
# auf die Beete.
enum Use { NONE, DRINK, POUR }

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var type: Type = Type.MISC
# Spieltext: keine Gedankenstriche, keine deutschen Anführungszeichen, keine
# Auslassungspunkte – die Pixelschrift kennt sie nicht.
@export_multiline var description: String = ""
@export var use: Use = Use.NONE
# Nur für Samen: welche Pflanze daraus wächst (ID in data/plants/).
@export var plant_id: String = ""

# Wirkung beim Ausgießen auf ein Beet: Pflanzen bis zu pour_radius Felder um
# das Beet wachsen pour_stages Stufen (0 = nur dieses Beet, 1 = 3×3).
@export_group("Pour")
@export var pour_radius: int = 0
# 99 = sofort erntereif.
@export var pour_stages: int = 1


## Gibt null zurück, wenn es keine Datei für diese ID gibt (auch bei "").
static func from_id(item_id: String) -> ItemData:
	if item_id == "":
		return null
	var path := "res://data/items/%s.tres" % item_id
	return load(path) if ResourceLoader.exists(path) else null


## Die Pflanze, die aus diesem Samen wächst, sonst null.
func plant() -> PlantData:
	return PlantData.from_id(plant_id) if type == Type.SEED and plant_id != "" else null
