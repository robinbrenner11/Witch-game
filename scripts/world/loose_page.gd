extends Node2D

## Eine lose Seite aus dem Buch der alten Hexe. E hebt sie auf; danach steht
## das Rezept im Buch und der Kessel kennt die Mischung. Sie glimmt nachts
## leicht magenta, damit man sie im Dunkeln entdecken kann.

# Ergebnis-ID des Rezepts, das auf der Seite steht (z. B. "potion_endless_night").
@export var recipe_result_id: String = ""


func _ready() -> void:
	# Schon aufgehoben (Spielstand, Rückkehr an den Ort)? Dann gibt es sie nicht mehr.
	if Journal.is_page_found(recipe_result_id):
		queue_free()


func _on_interactable_interacted(_player: Node2D) -> void:
	Journal.find_page(recipe_result_id)
	if Journal.has_book:
		Messages.post("Eine lose Seite. Sie gehört in das Buch.")
	else:
		Messages.post("Eine lose Seite aus einem alten Buch.")
	queue_free()
