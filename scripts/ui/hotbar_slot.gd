class_name HotbarSlot
extends TextureRect

## Ein einzelner Platz der Hotbar. Zeigt nur an, was man ihm gibt – woher die
## Daten kommen, weiß der Slot nicht.

const FRAME := preload("res://assets/ui/hotbar_slot.png")
const FRAME_SELECTED := preload("res://assets/ui/hotbar_slot_selected.png")

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count


func show_item(icon_texture: Texture2D, amount: int) -> void:
	icon.texture = icon_texture
	# Aufgebrauchte Items bleiben als blasser Schatten stehen: Man sieht, was
	# fehlt, und der Platz springt nicht weg, wenn es wieder da ist.
	icon.modulate.a = 1.0 if amount > 0 else 0.35
	count_label.text = str(amount) if amount > 0 else ""


func set_selected(selected: bool) -> void:
	texture = FRAME_SELECTED if selected else FRAME
