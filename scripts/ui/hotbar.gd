extends VBoxContainer

## Die Hotbar am unteren Bildrand. Sie zeigt die ersten Inventar-Plätze an
## (über ein InventoryGrid) und nimmt die Tasten 1–8 und das Mausrad entgegen.
## Was gewählt ist, merkt sich das Inventar – die Hotbar ist nur das Fenster
## darauf. Läuft auch, wenn das Spiel pausiert, damit man bei offenem
## Inventar-Fenster Items in die Hotbar ziehen kann.
## Über der Leiste blendet kurz ein Text auf: beim Wechseln der Name des
## Items, beim Bekommen z. B. "+1 Wachstumstrank".

# Sekunden, die der Name sichtbar bleibt, bevor er ausblendet.
const NAME_SHOW_TIME := 1.5
const NAME_FADE_TIME := 0.4

var _name_tween: Tween

@onready var item_name_label: Label = $ItemName


func _ready() -> void:
	# Die Plätze selbst zeichnet das InventoryGrid neu. Hier nur der Text.
	Inventory.selection_changed.connect(_show_item_name)
	Inventory.item_added.connect(_on_item_added)


func _show_item_name() -> void:
	_flash_text(Inventory.display_name_for(Inventory.selected_item_id()))


func _on_item_added(item_id: String, amount: int) -> void:
	_flash_text("+%d %s" % [amount, Inventory.display_name_for(item_id)])


func _flash_text(text: String) -> void:
	item_name_label.text = text
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
