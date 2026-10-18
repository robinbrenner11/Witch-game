extends Node2D

## Eine lose Seite aus Vesperas Grimoire. E hebt sie auf; danach steht sie im
## Buch (z. B. ein Rezept, das dann auch der Kessel kennt). Sie glimmt nachts
## leicht magenta, damit man sie im Dunkeln entdecken kann.

# ID der Seite in data/grimoire/pages/ (z. B. "page_recipe_endless_night").
@export var page_id: String = ""
# Bei zerrissenen Seiten: welcher Teil hier liegt (0, 1, 2 …).
@export var fragment: int = 0
# Versteckt: nur zu sehen und aufzuheben, solange Flüssiges Mondlicht wirkt
# (docs/design/grimoire.md, Abschnitt 2, Fundorte).
@export var moonlight_only: bool = false

# So oft wird geprüft, ob das Mondlicht wirkt (Sekunden).
const MOONLIGHT_CHECK := 0.25
const REVEAL_TIME := 0.6

var _check_wait := 0.0
var _revealed := true

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
	if moonlight_only:
		_set_revealed(false, true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	_check_wait -= delta
	if _check_wait > 0.0:
		return
	_check_wait = MOONLIGHT_CHECK
	var player := get_tree().get_first_node_in_group("player")
	var effects := player.get_node_or_null("PotionEffects") as PotionEffects if player else null
	var lit := effects != null and effects.is_active("moonlight")
	if lit != _revealed:
		_set_revealed(lit, false)


## Im Mondlicht taucht die Seite langsam auf, ohne verschwindet sie wieder.
func _set_revealed(revealed: bool, instant: bool) -> void:
	_revealed = revealed
	$Interactable.set_deferred("monitorable", revealed)
	$Glimmer.enabled = revealed
	if instant:
		modulate.a = 1.0 if revealed else 0.0
	else:
		create_tween().tween_property(self, "modulate:a", 1.0 if revealed else 0.0, REVEAL_TIME)


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_PICK_UP"


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
