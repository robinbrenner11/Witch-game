class_name DialogueData
extends Resource

## Ein Gespräch eines NPCs, als Datei in data/dialogue/<npc-id>/<id>.tres.
## Neue Gespräche sind neue Dateien. Beim Ansprechen gewinnt von allen
## Gesprächen, deren Bedingungen gerade passen, das mit der höchsten
## Priorität (bei Gleichstand zufällig). Ein Rückfall-Gespräch mit Priorität 0
## ohne Bedingungen sorgt dafür, dass er immer etwas sagt.

const FOLDER := "res://data/dialogue/"

# NPC-ID -> Array[DialogueData], einmal geladen.
static var _cache: Dictionary = {}

@export var id: String = ""
## Text-Schlüssel, eine Seite der Dialogbox pro Eintrag.
@export var lines: Array[String] = []
@export var priority: int = 0
## Nur ein einziges Mal (gemerkt als Flag "dlg_<npc>_<id>").
@export var once: bool = false
## Nur, wenn alle diese Flags gesetzt sind.
@export var requires_flags: Array[String] = []
## Nicht, sobald eines dieser Flags gesetzt ist.
@export var blocked_by_flags: Array[String] = []
## Nur in dieser Mondphase (Moon.Phase: 0 Neumond … 4 Vollmond). -1 = egal.
@export_range(-1, 4) var moon_phase: int = -1
## Nur im Zeitblock mit diesem Thema (ScheduleEntry.topic). Leer = immer.
@export var topic: String = ""
## Wird nach dem Gespräch gesetzt (WorldState), z. B. eine Freischaltung.
@export var sets_flag: String = ""


## Alle Gespräche dieses NPCs aus seinem Ordner.
static func all_for(npc_id: String) -> Array[DialogueData]:
	if not _cache.has(npc_id):
		var list: Array[DialogueData] = []
		var folder := FOLDER + npc_id + "/"
		if DirAccess.dir_exists_absolute(folder):
			for dialogue in DataFolder.load_all(folder):
				list.append(dialogue)
		_cache[npc_id] = list
	return _cache[npc_id]


## Das Gespräch, das jetzt dran ist, oder null.
static func pick(npc_id: String, current_topic: String) -> DialogueData:
	var best: Array[DialogueData] = []
	for dialogue in all_for(npc_id):
		if not dialogue.is_available(npc_id, current_topic):
			continue
		if best.is_empty() or dialogue.priority > best[0].priority:
			best = [dialogue]
		elif dialogue.priority == best[0].priority:
			best.append(dialogue)
	return best.pick_random() if not best.is_empty() else null


func is_available(npc_id: String, current_topic: String) -> bool:
	if once and WorldState.has_flag(said_flag(npc_id)):
		return false
	if topic != "" and topic != current_topic:
		return false
	if moon_phase >= 0 and Moon.phase() != moon_phase:
		return false
	return WorldState.has_all(requires_flags) and WorldState.has_none(blocked_by_flags)


func said_flag(npc_id: String) -> String:
	return "dlg_%s_%s" % [npc_id, id]
