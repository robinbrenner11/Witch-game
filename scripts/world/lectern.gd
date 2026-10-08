extends StaticBody2D

## Das Lesepult im Unterschlupf. Darauf liegt das Buch der alten Hexe, bis die
## Hexe es mitnimmt. Danach schlägt E am Pult das Buch auf.

const WITH_BOOK := preload("res://assets/environment/props/lectern_book.png")
const EMPTY := preload("res://assets/environment/props/lectern.png")

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	Grimoire.changed.connect(_update_look)
	_update_look()


func _on_interactable_interacted(_player: Node2D) -> void:
	if not Grimoire.has_book:
		Grimoire.find_book()
		Messages.post(tr("MSG_LECTERN_BOOK"))
	else:
		get_tree().call_group("grimoire_book", "open")


func _update_look() -> void:
	sprite.texture = EMPTY if Grimoire.has_book else WITH_BOOK
