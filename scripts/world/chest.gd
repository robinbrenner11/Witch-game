@tool
class_name Chest
extends Decor

## Die Truhe im Unterschlupf, das Lager der Hexe. E öffnet das Truhen-Fenster;
## solange es offen ist, steht der Deckel offen (Frame 1 der Grafik). Was
## drinliegt, steht im Autoload Inventory (Truhenplätze), nicht hier: So
## könnten weitere Truhen später denselben Inhalt zeigen.

const CLOSED_FRAME := 0
const OPEN_FRAME := 1


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 20)
	shape.shape = rect
	interactable.position = Vector2(0, -12)
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_OPEN"


func _on_interacted(_player: Node2D) -> void:
	var window := get_tree().get_first_node_in_group("chest_window") as ChestWindow
	if window == null:
		return
	_set_lid(OPEN_FRAME)
	window.open()
	await window.closed
	_set_lid(CLOSED_FRAME)


func _set_lid(frame: int) -> void:
	if sprite:
		sprite.frame = frame
