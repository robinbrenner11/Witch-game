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
# Samen, die man beim Ernten zusätzlich zurückbekommt. Vorerst 1, damit der
# Garten-Pilot nicht ausblutet – später evtl. 0 und Samen kommen anders rein.
@export var seeds_on_harvest: int = 1

# Aura: wirkt auf die Beete ringsum. Allgemein gehalten, damit später auch
# positive Auren (z. B. "nebenan wachsen nur perfekte Pflanzen") nur neue
# Werte in den Pflanzendaten sind. Nachtschatten ist die erste Aura.
enum AuraEffect { NONE, BLOCK_GROWTH }

@export_group("Aura")
@export var aura_effect: AuraEffect = AuraEffect.NONE
# 1 = die 8 Nachbarfelder (auch diagonal), 2 = 5×5 usw.
@export var aura_radius: int = 1
# Ab welcher Wachstumsstufe die Aura wirkt (0 = Samen).
@export var aura_min_stage: int = 0
# Ob die Aura auch Pflanzen derselben Art trifft.
@export var aura_affects_own_kind: bool = false

# Leuchten im Reif-Stadium (nachts). Ohne Textur leuchtet die Pflanze nicht.
@export_group("Glow")
@export var glow_texture: Texture2D
@export var glow_color: Color = Color.WHITE
@export var glow_energy: float = 1.0
# Mittelpunkt des Lichts relativ zum Wurzelpunkt der Pflanze.
@export var glow_offset: Vector2 = Vector2.ZERO


## Lädt eine Pflanzenart über ihre ID. Funktioniert, weil jede Art unter
## data/plants/<id>.tres liegt – load() merkt sich geladene Dateien, das
## ist also auch bei häufigem Aufruf billig.
static func from_id(plant_id: String) -> PlantData:
	return load("res://data/plants/%s.tres" % plant_id)


func seed_item_id() -> String:
	return "seed_" + id


func crop_item_id() -> String:
	return "crop_" + id
