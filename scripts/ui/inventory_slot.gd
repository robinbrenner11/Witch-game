class_name InventorySlot
extends TextureRect

## Ein Inventar-Platz (Hotbar, Inventar-Fenster, später Brau-Fenster). Zeigt
## an, was auf seinem Platz liegt, und lässt sich per Drag & Drop mit einem
## anderen Platz tauschen.

signal hovered(slot_index: int)

const FRAME := preload("res://assets/ui/hotbar_slot.png")
const FRAME_SELECTED := preload("res://assets/ui/hotbar_slot_selected.png")

# Die Rahmen-Grafik ist 2× vorskaliert (40 px). In Fenstern, die selbst
# doppelt so groß angezeigt werden (Brau-Fenster, scale = 2), braucht der Platz
# genau die halbe Größe – exakt halbiert bleibt er pixelscharf.
const FULL_SIZE := 40

# Welcher Platz im Inventar (0–23). Setzt das InventoryGrid.
var slot_index: int = 0
# 40 = normal (Hotbar), 20 = halb. Muss vor dem Einfügen gesetzt sein.
var slot_size: int = FULL_SIZE

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count


func _ready() -> void:
	# Nur Controls, die Mausereignisse annehmen, können gezogen werden.
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hovered.emit(slot_index))
	# Über die Gruppe findet das Inventar-Fenster alle Plätze, auch die der
	# Hotbar, um anzuzeigen, worüber die Maus gerade ist.
	add_to_group("inventory_slots")
	if slot_size != FULL_SIZE:
		_shrink()


func _shrink() -> void:
	var factor := float(slot_size) / FULL_SIZE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	custom_minimum_size = Vector2.ONE * slot_size
	icon.position *= factor
	icon.size *= factor
	count_label.offset_left *= factor
	count_label.offset_top *= factor
	count_label.offset_right *= factor
	count_label.offset_bottom *= factor
	count_label.add_theme_font_size_override("font_size", roundi(14 * factor))


func show_item(icon_texture: Texture2D, amount: int) -> void:
	icon.texture = icon_texture
	count_label.text = str(amount) if amount > 0 else ""


func set_selected(selected: bool) -> void:
	texture = FRAME_SELECTED if selected else FRAME


# Drag & Drop ist in Godot in jedes Control eingebaut: Beim Ziehen fragt
# Godot _get_drag_data (was wird gezogen?), über einem Ziel _can_drop_data
# (darf es hier hin?) und beim Loslassen _drop_data.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if Inventory.item_in_slot(slot_index) == "":
		return null
	# Das Icon klebt beim Ziehen mittig an der Maus.
	var preview := TextureRect.new()
	preview.texture = icon.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# So groß, wie das Icon auf dem Bildschirm erscheint – auch in Fenstern,
	# die doppelt so groß angezeigt werden.
	var shown_size := icon.size * icon.get_global_transform().get_scale()
	preview.size = shown_size
	preview.position = -shown_size / 2
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"inventory_slot": slot_index}


# Zwei Arten von gezogenen Dingen kommen hier an: ein anderer Inventar-Platz
# (tauschen) oder etwas von außerhalb des Inventars, z. B. eine Zutat aus dem
# Kessel. Das bringt in "return_item" selbst mit, wie es zurückgelegt wird –
# so muss der Platz den Kessel nicht kennen.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data.has("inventory_slot") or data.has("return_item"))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.has("inventory_slot"):
		Inventory.move(data["inventory_slot"], slot_index)
	else:
		data["return_item"].call()
