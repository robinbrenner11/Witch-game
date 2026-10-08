class_name OfferSlot
extends Control

## Ein Opfer-Feld am Lesepult: zeigt, welches Item die befallene Seite
## verlangt und wie viele schon daliegen. Items zieht man aus dem Inventar
## hierher (wie beim Brau-Fenster); Rechtsklick legt sie zurück.

var item_id := ""
var need := 1
var given := 0
var offering: SpreadOffering

# Das Feld hält seine Textur selbst fest (siehe BookSlot).
var _icon: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(BookStyle.SLOT_SIZE, BookStyle.SLOT_SIZE + 12)
	_icon = Inventory.icon_for(item_id)
	tooltip_text = Inventory.display_name_for(item_id)


func _draw() -> void:
	var box := Rect2(0, 0, BookStyle.SLOT_SIZE, BookStyle.SLOT_SIZE)
	draw_rect(box, BookStyle.SHEET_SHADOW)
	BookStyle.draw_frame(self, box, BookStyle.GOLD if given >= need else BookStyle.INK_FAINT)
	# Noch nichts da: das verlangte Item nur als blasser Schatten.
	var tint := Color.WHITE if given > 0 else Color(BookStyle.AUBERGINE, 0.35)
	draw_texture(_icon, (box.size - Vector2(16, 16)) / 2.0, tint)
	var color := BookStyle.INK if given >= need else BookStyle.MISSING
	draw_string(get_theme_default_font(), Vector2(2, box.size.y + 10), "%d/%d" % [given, need],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_slot") and given < need \
		and Inventory.item_in_slot(data["inventory_slot"]) == item_id


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	offering.give(item_id, data["inventory_slot"])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		offering.take_back(item_id)
		accept_event()
