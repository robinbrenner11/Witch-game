extends Control

## Inventar-Fenster (Tab): zeigt die Plätze 9–24 direkt über der Hotbar. Die
## Hotbar bleibt sichtbar und ist die unterste Reihe; Items lassen sich
## zwischen allen Plätzen ziehen. Fährt die Maus über ein Item, stehen oben
## sein Name, seine Beschreibung und wofür es gut ist (pflanzen, trinken,
## ausgießen, Zutat).
##
## Solange das Fenster offen ist, ist das Spiel pausiert: Zeit, Hexe und
## Pflanzen stehen. Das Fenster selbst läuft weiter (process_mode = Always).

@onready var info: Control = $Box/Info
@onready var name_label: Label = $Box/Info/InfoBox/Name
@onready var description_label: Label = $Box/Info/InfoBox/Description
@onready var use_label: Label = $Box/Info/InfoBox/Use


func _ready() -> void:
	hide()
	_show_item("")


func _unhandled_input(event: InputEvent) -> void:
	# Ist schon ein anderes Fenster offen (Spiel pausiert), nicht öffnen.
	if not visible and get_tree().paused:
		return
	if event.is_action_pressed("inventory") or (visible and event.is_action_pressed("ui_cancel")):
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	Sfx.play("ui/open" if open else "ui/close")
	visible = open
	# Pausiert alle Nodes, deren process_mode nicht "Always" ist.
	get_tree().paused = open
	_show_item("")
	if open:
		# Die Plätze werden zur Laufzeit erzeugt (auch die der Hotbar), deshalb
		# erst beim Öffnen verbinden statt in _ready.
		for slot in get_tree().get_nodes_in_group("inventory_slots"):
			if not slot.hovered.is_connected(_on_slot_hovered):
				slot.hovered.connect(_on_slot_hovered)


func _on_slot_hovered(slot_index: int) -> void:
	if visible:
		_show_item(Inventory.item_in_slot(slot_index))


## Name groß, darunter die Beschreibung (Stimmung) und in Gold, wofür das
## Item gut ist, auf einer eigenen Tafel über den Plätzen. Ohne Item unter
## der Maus ist die Tafel weg, damit das Fenster ruhig bleibt.
func _show_item(item_id: String) -> void:
	var item := ItemData.from_id(item_id)
	info.visible = item != null
	name_label.text = Inventory.display_name_for(item_id)
	description_label.text = tr(item.description) if item and item.description != "" else ""
	use_label.text = _use_text(item)
	description_label.visible = description_label.text != ""
	use_label.visible = use_label.text != ""


func _use_text(item: ItemData) -> String:
	if item == null:
		return ""
	match item.use:
		ItemData.Use.DRINK:
			return "%s  ·  %s" % [tr("BOOK_USE_DRINK"), InputHints.key_for("use_item")]
		ItemData.Use.POUR:
			return "%s  ·  %s" % [tr("BOOK_USE_POUR"), InputHints.key_for("interact")]
		ItemData.Use.THROW:
			return "%s  ·  %s" % [tr("BOOK_USE_THROW"), InputHints.key_for("potion_quick")]
	match item.type:
		ItemData.Type.SEED:
			return tr("ITEM_USE_SEED")
		ItemData.Type.INGREDIENT:
			return tr("ITEM_USE_INGREDIENT")
	return ""
