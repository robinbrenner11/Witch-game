class_name NpcData
extends Resource

## Wer ein NPC ist und wann er wo steht, als Datei in data/npcs/<id>.tres.
## Die Szene (scenes/npcs/) zeigt ihn nur an; neue Routinen oder Namen sind
## so eine Änderung an der Datei, kein Code. Plan: docs/design/dorf_hub_plan.md.

const FOLDER := "res://data/npcs/"

@export var id: String = ""
## Schlüssel in data/translations/texts.csv, z. B. "NPC_WATCHMAN".
@export var name_key: String = ""
## Kurz, was er tut (für das Grimoire-Kapitel People, später).
@export var role_key: String = ""
## Erst da, wenn dieses Flag gesetzt ist (WorldState). Leer = von Anfang an.
## Neue NPCs erscheinen nur durch eine Aktion der Spielerin (game_design 8).
@export var appears_flag: String = ""
## Tagesroutine. Die Reihenfolge in der Datei ist egal.
@export var schedule: Array[ScheduleEntry] = []
## Pixel pro Sekunde beim Laufen (die Hexe läuft 80).
@export var walk_speed: float = 40.0
## Für die Dialogbox. Leer = ohne Portrait.
@export var portrait: Texture2D


## Minuten seit Beginn der Nacht (18:00), 0 bis unter 1440.
static func to_night_minute(minutes: float) -> float:
	return fposmod(minutes - DayCycle.NIGHT_START, DayCycle.MINUTES_PER_DAY)


## Der Block, der zu dieser Uhrzeit gilt (Minuten seit Mitternacht), oder
## null, wenn er gerade nicht unterwegs ist (tagsüber ab 6 Uhr).
func entry_at(minutes: float) -> ScheduleEntry:
	var now := to_night_minute(minutes)
	# Ab dem Morgen bis zur nächsten Nacht schläft er.
	if now >= to_night_minute(DayCycle.MORNING):
		return null
	var current: ScheduleEntry = null
	for entry in schedule:
		if entry.night_minute() <= now and (current == null or entry.night_minute() > current.night_minute()):
			current = entry
	return current


func is_present() -> bool:
	return appears_flag == "" or WorldState.has_flag(appears_flag)
