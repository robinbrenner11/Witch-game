class_name ItemData
extends Resource

## Beschreibt ein Item als Datendatei in data/items/<id>.tres – Tränke, später
## Kristalle, Werkzeuge … Neue Items brauchen so keinen neuen Code.
## (Samen und Ernte kommen vorerst noch aus den Pflanzendaten.)

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D


## Gibt null zurück, wenn es keine Datei für diese ID gibt.
static func from_id(item_id: String) -> ItemData:
	var path := "res://data/items/%s.tres" % item_id
	return load(path) if ResourceLoader.exists(path) else null
