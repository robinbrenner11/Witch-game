extends StaticBody2D

## Anschlagbrett im Dorf: E liest die Aushänge in der Dialogbox. Die Zeilen
## sind Text-Schlüssel und werden im Inspector eingetragen. Später hängen hier
## auch Gesuche zum Tauschen (siehe docs/design/dorf_hub_plan.md).

## Text im Namensschild der Dialogbox.
@export var title_key: String = "NOTICE_BOARD"
## Aushänge, einer pro Seite der Dialogbox.
@export var lines: Array[String] = []


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_READ"


func _on_interactable_interacted(_player: Node2D) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box:
		Sfx.play("ui/page_turn")
		box.show_lines(title_key, lines)
