extends PanelContainer

## Die Hotbar am unteren Bildrand. Sie zeigt die ersten Inventar-Plätze an und
## nimmt die Tasten 1–8 und das Mausrad entgegen. Was gewählt ist, merkt sich
## das Inventar – die Hotbar ist nur das Fenster darauf.

const SLOT_SCENE := preload("res://scenes/ui/hotbar_slot.tscn")

var _slots: Array[HotbarSlot] = []

@onready var slot_row: HBoxContainer = $Slots


func _ready() -> void:
	# Slots per Code statt von Hand in der Szene, damit HOTBAR_SIZE die
	# einzige Stelle ist, an der die Anzahl steht.
	for i in Inventory.HOTBAR_SIZE:
		var slot: HotbarSlot = SLOT_SCENE.instantiate()
		slot_row.add_child(slot)
		_slots.append(slot)
	# Signale: Das Inventar ruft "Bescheid!", die Hotbar zeichnet sich neu.
	# So muss niemand jeden Frame nachsehen, ob sich etwas geändert hat.
	Inventory.changed.connect(_refresh)
	Inventory.selection_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in _slots.size():
		var item_id := Inventory.item_in_slot(i)
		_slots[i].show_item(Inventory.icon_for(item_id), Inventory.count(item_id))
		_slots[i].set_selected(i == Inventory.selected_slot)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hotbar_next"):
		Inventory.selected_slot += 1
	elif event.is_action_pressed("hotbar_previous"):
		Inventory.selected_slot -= 1
	else:
		var slot := _pressed_slot_key(event)
		if slot == -1:
			return
		Inventory.selected_slot = slot
	# Verhindert, dass dieselbe Eingabe noch woanders etwas auslöst.
	get_viewport().set_input_as_handled()


## Welche der Tasten 1–8 gedrückt wurde (als Platz 0–7), sonst -1.
func _pressed_slot_key(event: InputEvent) -> int:
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			return i
	return -1
