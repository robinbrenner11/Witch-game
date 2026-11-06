class_name WitchRing
extends Node2D

## Hexenring als Schnellreise (game_design.md, Abschnitt 4 und 10): Ein Ring
## schläft, bis sein Gebiet geheilt ist. Wach führt E zu einer Auswahl der
## anderen wachen Ringe; die Hexe tritt hinein und kommt im anderen Ring
## heraus. Der Ring im Garten ist das Gegenstück zu jedem anderen.
##
## Welche Ringe es gibt, steht in NETWORK. Der Node heißt im Ort
## "WitchRing_<id>", damit Main.travel ihn als Ankunftsort findet.

## id -> Ort, Name (Text-Schlüssel) und Flag, ab dem der Ring wach ist.
const NETWORK := {
	"garden": {"scene": "res://scenes/world/garden.tscn", "name": "RING_GARDEN", "flag": "bloom_heart_1_cleansed"},
	"forest": {"scene": "res://scenes/world/forest.tscn", "name": "RING_FOREST", "flag": "bloom_heart_1_cleansed"},
}
const NODE_PREFIX := "WitchRing_"
const AWAKE_COLOR := Color(0.85, 0.25, 0.6, 1)

@export var ring_id: String = "forest"

var _decor: Decor


func _ready() -> void:
	name = NODE_PREFIX + ring_id
	_decor = get_node_or_null("MushroomRing") as Decor
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 36)
	shape.shape = rect
	interactable.position = Vector2(0, -18)
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interactable_interacted)
	add_child(interactable)
	WorldState.flag_changed.connect(func(_flag: String) -> void: _update_look())
	_update_look()


func is_awake() -> bool:
	return WorldState.has_flag(String(NETWORK[ring_id]["flag"]))


## Andere wache Ringe, in die man von hier aus reisen kann.
func destinations() -> Array[String]:
	var result: Array[String] = []
	for id: String in NETWORK:
		if id != ring_id and WorldState.has_flag(String(NETWORK[id]["flag"])):
			result.append(id)
	return result


## Ankunft: in der Mitte des Rings (wie Exit.spawn_position()).
func spawn_position() -> Vector2:
	return global_position + Vector2(0, -16)


func interaction_prompt() -> String:
	return "PROMPT_RING_TRAVEL" if is_awake() and not destinations().is_empty() else "PROMPT_LOOK"


func _on_interactable_interacted(_player: Node2D) -> void:
	if not is_awake() or destinations().is_empty():
		Messages.post(tr("LOOK_RING_DORMANT"))
		return
	var targets := destinations()
	var options: Array[String] = []
	for id in targets:
		options.append(tr("RING_TRAVEL_TO") % tr(String(NETWORK[id]["name"])))
	options.append(tr("RING_STAY"))
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		return
	var picked := await box.choose("RING_NAME", options)
	if picked < 0 or picked >= targets.size():
		return
	travel_to(targets[picked])


func travel_to(id: String) -> void:
	CombatFx.sparks(get_parent(), global_position + Vector2(0, -16), AWAKE_COLOR, 24, 60.0)
	Sfx.play("brewing/wisp_appear")
	Grimoire.report("ring_travel", {"id": id})
	var main := get_tree().get_first_node_in_group("main")
	if main:
		main.travel(String(NETWORK[id]["scene"]), NODE_PREFIX + id)


## Schlafend glimmt der Ring nur schwach (das Decor-Licht gedimmt).
func _update_look() -> void:
	if _decor:
		_decor.modulate = Color.WHITE if is_awake() else Color(0.55, 0.5, 0.6)
