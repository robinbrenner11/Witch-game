class_name InventoryGrid
extends GridContainer

## Zeigt einen Ausschnitt der Inventar-Plätze als Raster. Baustein für die
## Hotbar (Plätze 0–7), das Inventar-Fenster (8–23) und das Brau-Fenster.

const SLOT_SCENE := preload("res://scenes/ui/inventory_slot.tscn")

@export var first_slot: int = 0
@export var slot_count: int = Inventory.HOTBAR_SIZE
# 40 = normal, 20 = halbe Größe für doppelt groß angezeigte Fenster.
@export var slot_size: int = InventorySlot.FULL_SIZE

var _slots: Array[InventorySlot] = []


func _ready() -> void:
	# Plätze per Code statt von Hand in der Szene, damit die Anzahl nur an
	# einer Stelle steht.
	for i in slot_count:
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		slot.slot_index = first_slot + i
		slot.slot_size = slot_size
		add_child(slot)
		_slots.append(slot)
	Inventory.changed.connect(_refresh)
	Inventory.selection_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for slot in _slots:
		var item_id := Inventory.item_in_slot(slot.slot_index)
		slot.show_item(Inventory.icon_for(item_id), Inventory.count_in_slot(slot.slot_index))
		slot.set_selected(slot.slot_index == Inventory.selected_slot)
