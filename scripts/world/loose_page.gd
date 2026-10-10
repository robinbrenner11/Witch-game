extends Node2D

## Eine lose Seite aus Vesperas Grimoire. E hebt sie auf; danach steht sie im
## Buch (z. B. ein Rezept, das dann auch der Kessel kennt). Sie glimmt nachts
## leicht magenta, damit man sie im Dunkeln entdecken kann.

# ID der Seite in data/grimoire/pages/ (z. B. "page_recipe_endless_night").
@export var page_id: String = ""
# Bei zerrissenen Seiten: welcher Teil hier liegt (0, 1, 2 …).
@export var fragment: int = 0

# Befallene Seiten sehen welk aus, bis es eine eigene Grafik gibt.
const BLIGHTED_TINT := Color("#7C7C68")


func _ready() -> void:
	# Schon aufgehoben (Spielstand, Rückkehr an den Ort)? Dann gibt es sie nicht mehr.
	if Grimoire.has_fragment(page_id, fragment):
		queue_free()
		return
	var page := PageData.from_id(page_id)
	if page and page.state == PageData.State.BLIGHTED:
		$Sprite2D.modulate = BLIGHTED_TINT


func _on_interactable_interacted(_player: Node2D) -> void:
	Grimoire.find_page(page_id, fragment)
	Sfx.play("world/page_pickup")
	var page := PageData.from_id(page_id)
	if page and page.state == PageData.State.BLIGHTED:
		Messages.post(tr("MSG_PAGE_BLIGHTED"))
	elif page and page.state == PageData.State.FRAGMENTS and not Grimoire.is_page_readable(page_id):
		Messages.post(tr("MSG_PAGE_FRAGMENT") % [Grimoire.fragments_found(page_id), page.fragment_count])
	elif Grimoire.has_book:
		Messages.post(tr("MSG_PAGE_FOR_BOOK"))
	else:
		Messages.post(tr("MSG_PAGE_LOOSE"))
	queue_free()
