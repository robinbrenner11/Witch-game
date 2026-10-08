class_name DisciplineData
extends Resource

## Eine Disziplin (Herbalism, Brewing …), als Datei in data/grimoire/disciplines/.
## Steigt durch Tun auf: Andere Systeme melden Aktionen (Grimoire.report),
## hier steht, was welche Aktion bringt und was jede Stufe freischaltet.
## Design: docs/design/grimoire.md, Abschnitt 3.

const FOLDER := "res://data/grimoire/disciplines/"

static var _all: Dictionary[String, DisciplineData] = {}

# Gleich der Kapitel-ID im Grimoire.
@export var id: String = ""
# Höchststufe. Später 15/20 möglich: nur xp_curve und level_rewards verlängern.
@export var max_level: int = 10
# Gesamte Erfahrung, die für Stufe 1, 2, 3 … nötig ist (aufsteigend).
@export var xp_curve: Array[int] = []
# Aktion -> Erfahrung bei jeder Wiederholung (z. B. "harvest": 3).
@export var xp_small: Dictionary[String, int] = {}
# Aktion -> Erfahrung beim ersten Mal pro Sache (z. B. erste Ernte einer Pflanze).
@export var xp_first: Dictionary[String, int] = {}
# Wie oft pro Nacht dieselbe Aktion voll zählt; danach 50 %, ab der zweiten
# Schwelle 25 %. Das Zählen beginnt nach dem Schlafen neu.
@export var repeat_thresholds: Array[int] = [10, 20]
# Belohnung je Stufe: Eintrag 0 gehört zu Stufe 1. Leer (null) = Meilenstein
# oder nichts.
@export var level_rewards: Array[RewardData] = []
# Auf diesen Stufen wählt man einen Hexenpfad.
@export var milestone_levels: Array[int] = [5, 10]


static func from_id(discipline_id: String) -> DisciplineData:
	return all().get(discipline_id)


static func all() -> Dictionary[String, DisciplineData]:
	if _all.is_empty():
		for discipline in DataFolder.load_all(FOLDER):
			_all[discipline.id] = discipline
	return _all


## Stufe bei dieser Gesamterfahrung.
func level_for(xp: int) -> int:
	var level := 0
	for needed in xp_curve:
		if xp >= needed:
			level += 1
	return mini(level, max_level)


## Gesamterfahrung, ab der diese Stufe erreicht ist (0 für Stufe 0).
func xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	return xp_curve[mini(level, xp_curve.size()) - 1]


func reward_for_level(level: int) -> RewardData:
	if level < 1 or level > level_rewards.size():
		return null
	return level_rewards[level - 1]
