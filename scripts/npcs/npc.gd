class_name Npc
extends CharacterBody2D

## Ein NPC in der Welt. Wer er ist und wann er wo steht, kommt aus seinen
## Daten (NpcData); diese Szene zeigt ihn nur an. Beim Laden des Orts steht
## er sofort am Spot seines aktuellen Zeitblocks. Gehört der Block zu einem
## anderen Ort oder ist er gerade drinnen, ist er hier nicht zu sehen.
##
## Ansprechen: E öffnet die Dialogbox mit dem Gespräch, das gerade dran ist
## (DialogueData.pick). Danach werden Flags gesetzt und das Grimoire erfährt
## davon (report "talk").
##
## Der Ursprung ist der Fußpunkt, wie bei Hexe und Deko (Y-Sortierung).

# Wie oft er prüft, ob ein neuer Zeitblock begonnen hat (Sekunden). Öfter
# ist unnötig, eine Spielminute dauert eine Sekunde.
const CHECK_INTERVAL := 0.5

@export var data: NpcData

var _entry: ScheduleEntry
var _level: Level
var _check_time := 0.0
var _talking := false

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	add_to_group("npcs")
	_level = _find_level()
	if data == null or _level == null:
		push_warning("NPC %s: Daten oder Ort fehlen" % name)
		_set_present(false)
		set_process(false)
		return
	_update_entry(true)


func _process(delta: float) -> void:
	_check_time -= delta
	if _check_time <= 0.0:
		_check_time = CHECK_INTERVAL
		_update_entry(false)


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_TALK"


## Der Zeitblock, der gerade gilt (oder null).
func current_entry() -> ScheduleEntry:
	return _entry


func is_present() -> bool:
	return visible


func _update_entry(force: bool) -> void:
	var entry := data.entry_at(DayCycle.minutes) if data.is_present() else null
	if entry == _entry and not force:
		return
	_entry = entry
	var spot := _spot_for(entry)
	_set_present(spot != null)
	if spot:
		global_position = spot.global_position


## Der Spot, an dem er in diesem Block steht, oder null (anderer Ort, drinnen).
## Bei einer Streife zählt vorerst ihr erster Spot.
func _spot_for(entry: ScheduleEntry) -> Node2D:
	if entry == null or entry.level != _level.name:
		return null
	var spot_name := entry.patrol[0] if not entry.patrol.is_empty() else entry.spot
	if spot_name == "":
		return null
	var spot := _level.get_node_or_null("Spots/" + spot_name) as Node2D
	if spot == null:
		push_warning("NPC %s: Spot %s gibt es in %s nicht" % [data.id, spot_name, _level.name])
	return spot


## Nicht da heißt: unsichtbar, ohne Kollision und nicht ansprechbar. Der Node
## bleibt aber im Ort, damit er zu seinem nächsten Block wieder auftauchen kann.
func _set_present(present: bool) -> void:
	visible = present
	# set_deferred: Kollisionen darf man nicht mitten in der Physik-Berechnung
	# umschalten, deshalb erst am Ende des Frames.
	body_shape.set_deferred("disabled", not present)
	interactable.set_deferred("monitorable", present)


func _on_interactable_interacted(_player: Node2D) -> void:
	if _talking:
		return
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	var dialogue := DialogueData.pick(data.id, _entry.topic if _entry else "")
	if box == null or dialogue == null:
		return
	_talking = true
	await box.show_lines(data.name_key, dialogue.lines, data.portrait)
	_talking = false
	_after_talk(dialogue)


func _after_talk(dialogue: DialogueData) -> void:
	if dialogue.once:
		WorldState.set_flag(dialogue.said_flag(data.id))
	WorldState.set_flag(dialogue.sets_flag)
	WorldState.set_flag("met_" + data.id)
	Grimoire.report("talk", {"id": data.id})


func _find_level() -> Level:
	var node := get_parent()
	while node != null and not node is Level:
		node = node.get_parent()
	return node as Level
