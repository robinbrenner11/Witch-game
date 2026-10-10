class_name BrewSlot
extends TextureRect

## Ein Zutaten-Feld über dem Kessel. Nimmt Zutaten aus dem Inventar an;
## eine Zutat zieht man zurück ins Inventar oder holt sie per Rechtsklick
## heraus. Was im Kessel liegt, verwaltet das Brau-Fenster.

# Welche Zutat im Kessel dieses Feld zeigt. Setzt das Brau-Fenster.
var index: int = 0
var window: BrewWindow

@onready var icon: TextureRect = $Icon


func show_ingredient(icon_texture: Texture2D) -> void:
	icon.texture = icon_texture


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_slot") \
		and window.can_add(Inventory.item_in_slot(data["inventory_slot"]))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	window.add_from_inventory(data["inventory_slot"])


func _get_drag_data(_at_position: Vector2) -> Variant:
	if icon.texture == null or window.is_locked():
		return null
	var preview := TextureRect.new()
	preview.texture = icon.texture
	# Das Fenster ist doppelt so groß angezeigt, die Vorschau hängt aber
	# direkt am Bildschirm – also die Anzeigegröße nehmen.
	var shown_size := icon.size * icon.get_global_transform().get_scale()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = shown_size
	preview.position = -shown_size / 2
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	Sfx.play("ui/item_pick")
	# Siehe InventorySlot: Das Ziel ruft das hier auf, um die Zutat zurückzulegen.
	return {"return_item": window.return_ingredient.bind(index)}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		window.return_ingredient(index)
