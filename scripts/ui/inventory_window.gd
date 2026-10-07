extends Control

## Inventar-Fenster (Tab): zeigt die Plätze 9–24 direkt über der Hotbar. Die
## Hotbar bleibt sichtbar und ist die unterste Reihe; Items lassen sich
## zwischen allen Plätzen ziehen. Fährt die Maus über ein Item, steht oben
## sein Name. (Die Beschreibungen kommen später ins Rezeptbuch.)
##
## Solange das Fenster offen ist, ist das Spiel pausiert: Zeit, Hexe und
## Pflanzen stehen. Das Fenster selbst läuft weiter (process_mode = Always).

@onready var name_label: Label = $Box/Name


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	# Ist schon ein anderes Fenster offen (Spiel pausiert), nicht öffnen.
	if not visible and get_tree().paused:
		return
	if event.is_action_pressed("inventory") or (visible and event.is_action_pressed("ui_cancel")):
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	visible = open
	# Pausiert alle Nodes, deren process_mode nicht "Always" ist.
	get_tree().paused = open
	name_label.text = ""
	if open:
		# Die Plätze werden zur Laufzeit erzeugt (auch die der Hotbar), deshalb
		# erst beim Öffnen verbinden statt in _ready.
		for slot in get_tree().get_nodes_in_group("inventory_slots"):
			if not slot.hovered.is_connected(_on_slot_hovered):
				slot.hovered.connect(_on_slot_hovered)


func _on_slot_hovered(slot_index: int) -> void:
	if visible:
		name_label.text = Inventory.display_name_for(Inventory.item_in_slot(slot_index))
