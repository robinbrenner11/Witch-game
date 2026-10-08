extends StaticBody2D

## Das Lesepult im Unterschlupf. Darauf liegt Vesperas Grimoire, bis die
## Hexe es mitnimmt. Danach schlägt E am Pult das Buch auf: Liegen befallene
## Seiten bereit, gleich beim Opfer, sonst normal. Am Pult lassen sich auch
## Hexenpfade wechseln.

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
		var book := get_tree().get_first_node_in_group("grimoire_book") as GrimoireBook
		if not Grimoire.blighted_pages().is_empty():
			book.open_offering()
		else:
			book.open("", false, true)


func _update_look() -> void:
	sprite.texture = EMPTY if Grimoire.has_book else WITH_BOOK
