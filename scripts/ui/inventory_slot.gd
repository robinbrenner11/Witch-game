class_name InventorySlot
extends TextureRect

## Ein Inventar-Platz (Hotbar, Inventar-Fenster, später Brau-Fenster). Zeigt
## an, was auf seinem Platz liegt, und lässt sich per Drag & Drop mit einem
## anderen Platz tauschen.

signal hovered(slot_index: int)

const FRAME := preload("res://assets/ui/hotbar_slot.png")
const FRAME_SELECTED := preload("res://assets/ui/hotbar_slot_selected.png")

# Welcher Platz im Inventar (0–23). Setzt das InventoryGrid.
var slot_index: int = 0

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count


func _ready() -> void:
	# Nur Controls, die Mausereignisse annehmen, können gezogen werden.
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hovered.emit(slot_index))
	# Über die Gruppe findet das Inventar-Fenster alle Plätze, auch die der
	# Hotbar, um anzuzeigen, worüber die Maus gerade ist.
	add_to_group("inventory_slots")


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
	preview.size = icon.size
	preview.position = -icon.size / 2
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"inventory_slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_slot")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	Inventory.move(data["inventory_slot"], slot_index)
