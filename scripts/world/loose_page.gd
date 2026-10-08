extends Node2D

## Eine lose Seite aus Vesperas Grimoire. E hebt sie auf; danach steht sie im
## Buch (z. B. ein Rezept, das dann auch der Kessel kennt). Sie glimmt nachts
## leicht magenta, damit man sie im Dunkeln entdecken kann.

# ID der Seite in data/grimoire/pages/ (z. B. "page_recipe_endless_night").
@export var page_id: String = ""


func _ready() -> void:
	# Schon aufgehoben (Spielstand, Rückkehr an den Ort)? Dann gibt es sie nicht mehr.
	if Grimoire.is_page_found(page_id):
		queue_free()


func _on_interactable_interacted(_player: Node2D) -> void:
	Grimoire.find_page(page_id)
	if Grimoire.has_book:
		Messages.post(tr("MSG_PAGE_FOR_BOOK"))
	else:
		Messages.post(tr("MSG_PAGE_LOOSE"))
	queue_free()
