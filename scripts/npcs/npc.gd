class_name Npc
extends CharacterBody2D

## Ein NPC in der Welt. Wer er ist und wann er wo steht, kommt aus seinen
## Daten (NpcData); diese Szene zeigt ihn nur an.
##
## Beim Laden des Orts steht er sofort am Spot seines aktuellen Zeitblocks.
## Beginnt ein neuer Block, während man zusieht, läuft er in gerader Linie
## dorthin. Bei einer Streife läuft er ihre Spots im Kreis ab und bleibt an
## jedem kurz stehen. Gehört der Block zu einem anderen Ort oder ist er gerade
## drinnen, ist er hier nicht zu sehen. Ein Navigationsnetz gibt es bewusst
## nicht: Die Spots sind so gesetzt, dass die Wege frei sind.
##
## Ansprechen: E öffnet die Dialogbox mit dem Gespräch, das gerade dran ist
## (DialogueData.pick). Danach werden Flags gesetzt und das Grimoire erfährt
## davon (report "talk").
##
## Der Ursprung ist der Fußpunkt, wie bei Hexe und Deko (Y-Sortierung).

# Wie oft er prüft, ob ein neuer Zeitblock begonnen hat (Sekunden). Öfter
# ist unnötig, eine Spielminute dauert eine Sekunde.
const CHECK_INTERVAL := 0.5
# So lange bleibt er auf einer Streife an jedem Spot stehen (Sekunden).
const PATROL_PAUSE := 3.0
# Nach einem Gespräch wartet er kurz, bevor er weitergeht.
const TALK_PAUSE := 1.5
# Kommt er so lange kaum voran (z. B. an einer Ecke hängen geblieben), steht
# er einfach am Ziel. Lieber ein Sprung als ewiges Schieben an der Wand.
const STUCK_LIMIT := 3.0
# Wippen beim Laufen: ein Pixel, so oft pro Sekunde.
const BOB_PER_SECOND := 5.0

@export var data: NpcData

var _entry: ScheduleEntry
var _level: Level
var _check_time := 0.0
var _talking := false
# Wohin er gerade läuft (null = er steht).
var _target: Node2D
# Wartezeit, bevor er weiterläuft (Streife, nach Gesprächen).
var _wait := 0.0
var _patrol_index := 0
var _stuck_time := 0.0
var _walk_time := 0.0

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interactable: Interactable = $Interactable
@onready var figure: Node2D = $Figure


func _ready() -> void:
	add_to_group("npcs")
	_level = _find_level()
	if data == null or _level == null:
		push_warning("NPC %s: Daten oder Ort fehlen" % name)
		_set_present(false)
		set_process(false)
		set_physics_process(false)
		return
	_update_entry(true)


func _process(delta: float) -> void:
	_check_time -= delta
	if _check_time <= 0.0:
		_check_time = CHECK_INTERVAL
		_update_entry(false)


func _physics_process(delta: float) -> void:
	if _target == null or not visible:
		return
	if _wait > 0.0:
		_wait -= delta
		_show_walking(false, delta)
		return
	var to_target := _target.global_position - global_position
	var step := data.walk_speed * delta
	var motion := to_target.limit_length(step)
	if _blocked_by_witch(motion):
		# Steht die Hexe im Weg, bleibt er stehen statt sich an ihr
		# vorbeizuschieben. Das zählt nicht als Hängenbleiben.
		_show_walking(false, delta)
		return
	if to_target.length() <= step:
		global_position = _target.global_position
		_show_walking(false, delta)
		_on_arrived()
		return
	velocity = to_target.normalized() * data.walk_speed
	move_and_slide()
	_show_walking(true, delta)
	if to_target.x != 0.0:
		# Die Figur spiegeln, damit die Laterne auf der Seite der Laufrichtung ist.
		figure.scale.x = signf(to_target.x)
	_check_stuck(delta)


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_TALK"


## Der Zeitblock, der gerade gilt (oder null).
func current_entry() -> ScheduleEntry:
	return _entry


func is_present() -> bool:
	return visible


func is_walking() -> bool:
	return _target != null and _wait <= 0.0


func _update_entry(force: bool) -> void:
	var entry := data.entry_at(DayCycle.minutes) if data.is_present() else null
	if entry == _entry and not force:
		return
	_entry = entry
	_patrol_index = 0
	_wait = 0.0
	var spot := _first_spot(entry)
	if spot == null:
		_target = null
		_set_present(false)
		return
	if force or not visible:
		# Beim Laden des Orts oder wenn er gerade auftaucht: gleich dort.
		_set_present(true)
		global_position = spot.global_position
		_on_arrived()
	else:
		_target = spot


## Angekommen: auf einer Streife nach einer Pause zum nächsten Spot, sonst
## bleibt er stehen.
func _on_arrived() -> void:
	_target = null
	_stuck_time = 0.0
	if _entry == null or _entry.patrol.is_empty():
		return
	_patrol_index = (_patrol_index + 1) % _entry.patrol.size()
	_target = _spot_named(_entry.patrol[_patrol_index])
	_wait = PATROL_PAUSE


## Der erste Spot dieses Blocks, oder null (anderer Ort, drinnen).
func _first_spot(entry: ScheduleEntry) -> Node2D:
	if entry == null or entry.level != _level.name:
		return null
	return _spot_named(entry.patrol[0] if not entry.patrol.is_empty() else entry.spot)


func _spot_named(spot_name: String) -> Node2D:
	if spot_name == "":
		return null
	var spot := _level.get_node_or_null("Spots/" + spot_name) as Node2D
	if spot == null:
		push_warning("NPC %s: Spot %s gibt es in %s nicht" % [data.id, spot_name, _level.name])
	return spot


## test_move probiert die Bewegung aus, ohne sie zu machen, und sagt, womit
## er zusammenstoßen würde.
func _blocked_by_witch(motion: Vector2) -> bool:
	var hit := KinematicCollision2D.new()
	return test_move(global_transform, motion, hit) and hit.get_collider() is Player


func _check_stuck(delta: float) -> void:
	if get_real_velocity().length() < data.walk_speed * 0.2:
		_stuck_time += delta
		if _stuck_time > STUCK_LIMIT:
			push_warning("NPC %s kam nicht zu %s durch" % [data.id, _target.name])
			global_position = _target.global_position
			_on_arrived()
	else:
		_stuck_time = 0.0


## Platzhalter-Animation: Beim Laufen wippt die Figur um einen Pixel.
func _show_walking(walking: bool, delta: float) -> void:
	if walking:
		_walk_time += delta
		figure.position.y = -1.0 if fmod(_walk_time * BOB_PER_SECOND, 1.0) < 0.5 else 0.0
	else:
		_walk_time = 0.0
		figure.position.y = 0.0


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
	_wait = maxf(_wait, TALK_PAUSE)
	_after_talk(dialogue)


func _after_talk(dialogue: DialogueData) -> void:
	if dialogue.once:
		WorldState.set_flag(dialogue.said_flag(data.id))
	if dialogue.once_per_night != "":
		WorldState.mark_tonight(dialogue.night_key(data.id))
	WorldState.set_flag(dialogue.sets_flag)
	WorldState.set_flag("met_" + data.id)
	Grimoire.report("talk", {"id": data.id})
	if dialogue.hint_recipe != "":
		Grimoire.hint_ingredient(dialogue.hint_recipe, dialogue.hint_ingredient)
		Messages.post(tr("MSG_RUMOR"))
	if dialogue.after_message != "":
		Messages.post(tr(dialogue.after_message))


func _find_level() -> Level:
	var node := get_parent()
	while node != null and not node is Level:
		node = node.get_parent()
	return node as Level
