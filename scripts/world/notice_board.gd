extends StaticBody2D

## Anschlagbrett im Dorf. Hier hängen die Gesuche der Dorfbewohner (Autoload
## Requests) und ein paar feste Aushänge. E liest alles in der Dialogbox; hat
## die Hexe für einen Zettel alles dabei, gibt E stattdessen ab.
## Siehe docs/design/welt_und_items.md, Abschnitt 7.

## Text im Namensschild der Dialogbox.
@export var title_key: String = "NOTICE_BOARD"
## Feste Aushänge, einer pro Seite, nach den Gesuchen.
@export var lines: Array[String] = []


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_DELIVER" if not Requests.deliverable_ids().is_empty() else "PROMPT_READ"


func _on_interactable_interacted(_player: Node2D) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		return
	Sfx.play("ui/page_turn")
	var deliverable := Requests.deliverable_ids()
	if not deliverable.is_empty():
		var thanks: Array[String] = []
		for id in deliverable:
			var request := Requests.get_request(id)
			if Requests.deliver(id):
				thanks.append(request.thanks_key)
		if not thanks.is_empty():
			box.show_lines(title_key, thanks)
			return
	var pages := notes_pages()
	pages.append_array(lines)
	box.show_lines(title_key, pages)


## Eine Seite pro hängendem Zettel: Text, darunter was gesucht ist und was es gibt.
func notes_pages() -> Array[String]:
	var pages: Array[String] = []
	for id in Requests.active_ids():
		var request := Requests.get_request(id)
		var wanted := tr("REQUEST_WANTED") % [request.amount, Inventory.display_name_for(request.item_id),
				Inventory.count(request.item_id)]
		pages.append("%s\n%s %s" % [tr(request.text_key), wanted, tr("REQUEST_REWARD") % Requests.reward_text(request)])
	if pages.is_empty():
		pages.append("NOTICE_NO_REQUESTS")
	return pages
