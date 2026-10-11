@tool
class_name Weed
extends Decor

## Wildgras oder Unkraut, das die Hexe mit E wegräumt. Dabei bückt sie sich
## (harvest) und bekommt eine Zutat. Was wo wächst, steuert WildGrowth.

## Kommt, wenn sie weggeräumt ist. WildGrowth trägt das in Wilds ein.
signal collected

@export var drop_item_id: String = "wild_herb"

# Schon geschnitten oder ausgerissen (verhindert doppelte Beute).
var _cut := false


func _ready() -> void:
	rustle_when_near = not Engine.is_editor_hint()
	super()
	if Engine.is_editor_hint():
		return
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 16)
	shape.shape = rect
	interactable.position = Vector2(0, -8)
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_PULL"


## Von der Sichel geschnitten (Slash): ohne Bücken, Blätter fliegen. Passt
## nichts mehr in die Tasche, bleibt das Kraut als Fundstück liegen.
func cut() -> void:
	if _cut:
		return
	_cut = true
	if Inventory.add(drop_item_id):
		Sfx.play("ui/item_get")
	else:
		var drop := DroppedItem.new()
		drop.item_id = drop_item_id
		get_parent().add_child(drop)
		drop.global_position = global_position
	CombatFx.sparks(get_parent(), global_position + Vector2(0, -6), Color("#3F7D5A"), 8, 35.0, 80.0)
	Grimoire.report("clear", {"id": drop_item_id})
	collected.emit()
	queue_free()


func _on_interacted(player: Node2D) -> void:
	var witch := player as Player
	if not Inventory.has_room_for(drop_item_id):
		Messages.deny(tr("MSG_BAG_FULL"))
		return
	witch.play_action("harvest")
	# Weg ist es, wenn sie es herauszieht (Frame 3), wie beim Ernten.
	await witch.wait_for_action_frame(2)
	if _cut:
		return
	_cut = true
	Inventory.add(drop_item_id)
	Sfx.play("ui/item_get")
	Grimoire.report("clear", {"id": drop_item_id})
	collected.emit()
	queue_free()
