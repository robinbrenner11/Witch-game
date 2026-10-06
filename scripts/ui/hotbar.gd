extends VBoxContainer

## Die Hotbar am unteren Bildrand. Sie zeigt die ersten Inventar-Plätze an und
## nimmt die Tasten 1–8 und das Mausrad entgegen. Was gewählt ist, merkt sich
## das Inventar – die Hotbar ist nur das Fenster darauf.
## Beim Wechseln blendet über der Leiste kurz der Name des Items auf.

const SLOT_SCENE := preload("res://scenes/ui/hotbar_slot.tscn")
# Sekunden, die der Name sichtbar bleibt, bevor er ausblendet.
const NAME_SHOW_TIME := 1.5
const NAME_FADE_TIME := 0.4

var _slots: Array[HotbarSlot] = []
var _name_tween: Tween

@onready var slot_row: HBoxContainer = $Panel/Slots
@onready var item_name_label: Label = $ItemName


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
	Inventory.selection_changed.connect(_show_item_name)
	_refresh()


func _refresh() -> void:
	for i in _slots.size():
		var item_id := Inventory.item_in_slot(i)
		_slots[i].show_item(Inventory.icon_for(item_id), Inventory.count(item_id))
		_slots[i].set_selected(i == Inventory.selected_slot)


func _show_item_name() -> void:
	item_name_label.text = Inventory.display_name_for(Inventory.selected_item_id())
	item_name_label.modulate.a = 1.0
	# Ein Tween verändert einen Wert über Zeit, hier die Deckkraft. Ein noch
	# laufender Tween vom letzten Wechsel wird vorher gestoppt, sonst würden
	# beide gleichzeitig an der Deckkraft ziehen.
	if _name_tween:
		_name_tween.kill()
	_name_tween = create_tween()
	_name_tween.tween_interval(NAME_SHOW_TIME)
	_name_tween.tween_property(item_name_label, "modulate:a", 0.0, NAME_FADE_TIME)


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
