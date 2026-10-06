class_name PlantData
extends Resource

## Beschreibt eine Pflanzenart (Mondkelch, Alraune …). Jede Art ist eine
## .tres-Datei in data/plants/. Neue Pflanzen entstehen so ohne neuen Code –
## später kommen hier Wachstumsbedingungen, Licht, Ernte-Item usw. dazu.

# Gemeinsamer Schlüssel für Samen, Pflanze und Ernte (siehe docs/ASSETS.md).
@export var id: String = ""
@export var display_name: String = ""
# Spritesheet mit allen Wachstumsstufen nebeneinander, letzte = erntereif.
@export var stages_texture: Texture2D
@export var stage_count: int = 4
# Für das spätere Inventar.
@export var seed_icon: Texture2D
@export var crop_icon: Texture2D
