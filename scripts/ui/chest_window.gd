class_name ChestWindow
extends Control

## Das Truhen-Fenster: oben die Truhe, darunter die Tasche, ganz unten wie
## immer die Hotbar. Items zieht man zwischen allen Plätzen hin und her; ein
## Doppelklick legt einen ganzen Stapel auf die andere Seite. Fährt die Maus
## über ein Item, steht sein Name in der Überschrift.
##
## Solange es offen ist, ist das Spiel pausiert (wie Inventar und Kessel).
## Schließen mit E, Tab oder Esc. Die Truhe in der Welt (chest.gd) öffnet es.

## Kommt beim Schließen, damit die Truhe in der Welt ihren Deckel zuklappt.
signal closed

@onready var title: Label = %Title
@onready var chest_grid: InventoryGrid = %ChestGrid


func _ready() -> void:
	hide()
	add_to_group("chest_window")
	Inventory.changed.connect(_on_inventory_changed)


func open() -> void:
	chest_grid.set_slot_count(Inventory.chest_capacity)
	_show_title("")
	show()
	get_tree().paused = true
	# Uhr und Mondphase lägen bei großer Truhe unter dem Fenster.
	get_tree().call_group("clock", "hide")
	Sfx.play("ui/open")
	for slot in get_tree().get_nodes_in_group("inventory_slots"):
		if not slot.hovered.is_connected(_on_slot_hovered):
			slot.hovered.connect(_on_slot_hovered)


func close() -> void:
	hide()
	get_tree().paused = false
	get_tree().call_group("clock", "show")
	Sfx.play("ui/close")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("inventory") \
			or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Doppelklick auf einen Platz (siehe InventorySlot): ganzer Stapel auf die
## andere Seite. Ist drüben kein Platz, ein leiser Ton.
func quick_move(slot: int) -> void:
	if not visible or Inventory.item_in_slot(slot) == "":
		return
	if Inventory.transfer(slot):
		Sfx.play("ui/item_drop")
	else:
		Sfx.play("ui/denied")


func _on_slot_hovered(slot_index: int) -> void:
	if visible:
		_show_title(Inventory.item_in_slot(slot_index))


func _show_title(item_id: String) -> void:
	title.text = Inventory.display_name_for(item_id) if item_id != "" else tr("CHEST_TITLE")


# Die Truhe kann wachsen, während das Fenster offen ist (z. B. durch eine
# Belohnung, später).
func _on_inventory_changed() -> void:
	if visible:
		chest_grid.set_slot_count(Inventory.chest_capacity)
