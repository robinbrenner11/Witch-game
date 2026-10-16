@tool
extends Node2D

## Eine Stelle am Seeufer, an der sich der Mond spiegelt. Nur bei Vollmond
## kann die Hexe hier Mondwasser schöpfen, ein paar Fläschchen pro Nacht.
## Sonst ist es nur Wasser (docs/design/welt_und_items.md, Abschnitt 3).

const PER_NIGHT := 3
const GLINT := Color("#EADFCB")
const BLOCK := 4

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 24)
	shape.shape = rect
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Bei Vollmond flimmert die Spiegelung, sonst sieht man nur einen Hauch.
func _draw() -> void:
	var full := Engine.is_editor_hint() or Moon.is_full()
	var step := int(_time * 6.0)
	for i in 6:
		var x := (i * 7 + step * (i % 2 * 2 - 1)) % 28 - 14
		var y := (i % 3) * BLOCK - BLOCK
		var alpha := 0.55 if full else 0.08
		draw_rect(Rect2(Vector2(x, y).snapped(Vector2.ONE * BLOCK), Vector2(BLOCK * 2, BLOCK)), Color(GLINT, alpha))


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_SCOOP" if Moon.is_full() and _left_tonight() > 0 else "PROMPT_LOOK"


func _left_tonight() -> int:
	var left := PER_NIGHT
	for i in PER_NIGHT:
		if WorldState.did_tonight("moon_water/%d" % i):
			left -= 1
	return left


func _on_interacted(player: Node2D) -> void:
	if not Moon.is_full():
		Messages.post(tr("MSG_MOON_WATER_PLAIN"))
		return
	var left := _left_tonight()
	if left <= 0:
		Messages.post(tr("MSG_MOON_WATER_SPENT"))
		return
	if not Inventory.has_room_for("moon_water"):
		Messages.deny(tr("MSG_BAG_FULL"))
		return
	(player as Player).play_action("harvest")
	WorldState.mark_tonight("moon_water/%d" % (PER_NIGHT - left))
	Inventory.add("moon_water")
	Sfx.play_at("world/well_splash", global_position)
	Grimoire.report("forage", {"id": "moon_water"})
