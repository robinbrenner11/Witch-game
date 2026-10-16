class_name ScheduleEntry
extends Resource

## Ein Zeitblock in der Tagesroutine eines NPCs: ab dieser Uhrzeit ist er an
## diesem Ort und Spot, bis der nächste Block beginnt. Wird in NpcData
## eingebettet. Spots sind Marker2D-Nodes unter "Spots" im Level.

## Ab dieser Stunde (0–23) gilt der Block, z. B. 20 für 20:00 oder 2 für 2:00.
@export_range(0, 23) var start_hour: int = 18
## Minuten zur Stunde dazu, z. B. 40 für 5:40.
@export_range(0, 59) var start_minute: int = 0
## Name des Orts (Level-Node), z. B. "Village".
@export var level: String = "Village"
## Name des Spots im Level. Leer = drinnen, also nicht zu sehen.
@export var spot: String = ""
## Spots für eine Streife, die im Kreis abgelaufen wird. Leer = er steht am Spot.
@export var patrol: Array[String] = []
## Thema für Gespräche in diesem Block (siehe DialogueData.topic). Leer = keins.
@export var topic: String = ""
## Gilt nur in diesen Mondphasen (Moon.Phase), z. B. der Halbmondmarkt.
## Leer = jede Nacht.
@export var moon_phases: Array[int] = []


## Minuten seit Beginn der Nacht (18:00). So liegt ein Block um 2:00 hinter
## einem um 23:00, obwohl dazwischen Mitternacht ist.
func night_minute() -> float:
	return NpcData.to_night_minute(start_hour * 60.0 + start_minute)
