class_name BrewWindow
extends Control

## Das Brau-Fenster am Kessel. Zutaten zieht man aus dem Inventar in die
## Felder über dem Kessel. Die Felder wachsen mit: Ist eins belegt, erscheint
## das nächste, bis die Kapazität des Kessels erreicht ist. Kein festes Raster,
## weil die Reihenfolge egal ist und Zweier- wie Dreier-Rezepte sich fertig
## anfühlen sollen.
##
## Alle Grafiken sind in 1× gezeichnet; das Fenster wird doppelt so groß
## angezeigt (Window hat scale = 2). Positionen stammen aus
## docs/art/ui_generator/brew_window.py (window_v2).
##
## Solange es offen ist, ist das Spiel pausiert. Schließen (E oder Esc) legt
## nicht gebraute Zutaten zurück ins Inventar. Braut der Kessel schon, zeigt
## das Fenster die Zutaten nur an (gesperrt) – fertig ist der Trank am
## nächsten Morgen.

const SLOT_SCENE := preload("res://scenes/ui/brew_slot.tscn")
const CAULDRON := preload("res://assets/ui/brew_cauldron.png")
const CAULDRON_READY := preload("res://assets/ui/brew_cauldron_ready.png")
const ARROW := preload("res://assets/ui/brew_arrow.png")
const ARROW_ACTIVE := preload("res://assets/ui/brew_arrow_active.png")
const PIP := preload("res://assets/ui/brew_pip.png")
const PIP_EMPTY := preload("res://assets/ui/brew_pip_empty.png")
const UNKNOWN := preload("res://assets/ui/brew_unknown.png")

# Layout in 1×-Pixeln (siehe Generator).
const CAULDRON_CENTER_X := 62
const SLOT_BASE_Y := 16
const SLOT_SPACING := 22
const PIP_Y := 76
const PIP_SPACING := 7

# Was gerade im Kessel liegt (aus dem Inventar genommen).
var _ingredients: Array[String] = []

@onready var cauldron: TextureRect = $Window/Cauldron
@onready var slots: Control = $Window/Slots
@onready var pips: Control = $Window/Pips
@onready var result_name: Label = $Window/ResultName
@onready var arrow: TextureRect = $Window/Arrow
@onready var result_icon: TextureRect = $Window/ResultIcon
@onready var brew_button: Button = $Window/BrewButton
@onready var divider: TextureRect = $Window/Divider


func _ready() -> void:
	hide()
	add_to_group("brew_window")
	_build_divider()


func open() -> void:
	show()
	get_tree().paused = true
	# Das Inventar steckt im Fenster, die Hotbar wäre doppelt.
	get_tree().call_group("hotbar", "hide")
	_refresh()


func close() -> void:
	# Was nicht mehr ins Inventar passt, bleibt im Kessel liegen und ist beim
	# nächsten Öffnen wieder da, statt zu verschwinden.
	var kept: Array[String] = []
	for item_id in _ingredients:
		if not Inventory.add(item_id):
			kept.append(item_id)
	_ingredients = kept
	if not kept.is_empty():
		Messages.post("Kein Platz mehr in der Tasche.")
	hide()
	get_tree().paused = false
	get_tree().call_group("hotbar", "show")


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()


## Während der Kessel braut, kann man nichts hineinlegen oder herausnehmen.
func is_locked() -> bool:
	return Brewing.is_brewing()


## In den Kessel darf alles vom Typ Zutat (Ernte, später z. B. Kristalle).
func can_add(item_id: String) -> bool:
	var item := ItemData.from_id(item_id)
	return not is_locked() and item != null and item.type == ItemData.Type.INGREDIENT 		and _ingredients.size() < Brewing.capacity


func add_from_inventory(inventory_slot: int) -> void:
	var item_id := Inventory.item_in_slot(inventory_slot)
	if can_add(item_id) and Inventory.remove_from_slot(inventory_slot):
		_ingredients.append(item_id)
		_refresh()


func return_ingredient(index: int) -> void:
	if is_locked() or index >= _ingredients.size():
		return
	# Bei vollem Inventar bleibt die Zutat lieber im Kessel.
	if not Inventory.add(_ingredients[index]):
		Messages.post("Kein Platz mehr in der Tasche.")
		return
	_ingredients.remove_at(index)
	_refresh()


## Die Zutaten wandern in den Kessel und brauen über Nacht.
func _on_brew_button_pressed() -> void:
	if _ingredients.size() < Brewing.MIN_INGREDIENTS or not Brewing.can_start():
		return
	Brewing.start(_ingredients)
	_ingredients.clear()
	_refresh()


## Was gerade in den Feldern liegt: beim Brauen der Kesselinhalt, sonst das,
## was die Hexe gerade hineinlegt.
func _shown_ingredients() -> Array[String]:
	return Brewing.brewing_ingredients() if is_locked() else _ingredients


func _refresh() -> void:
	_build_slots()
	_build_pips()
	var ready := _shown_ingredients().size() >= Brewing.MIN_INGREDIENTS
	cauldron.texture = CAULDRON_READY if ready else CAULDRON
	arrow.texture = ARROW_ACTIVE if ready else ARROW
	brew_button.disabled = not ready or is_locked()
	brew_button.text = "Braut" if is_locked() else "Brauen"
	_show_result(ready)


## Bekannte Kombinationen zeigen Trank und Namen, unbekannte nur "???" –
## was herauskommt, erfährt man erst beim Brauen.
func _show_result(ready: bool) -> void:
	if not ready:
		result_icon.texture = null
		result_name.text = ""
		return
	var known := Brewing.known_result(_shown_ingredients())
	if known == "":
		result_icon.texture = UNKNOWN
		result_name.text = "???"
	else:
		result_icon.texture = Inventory.icon_for(known)
		result_name.text = Inventory.display_name_for(known)


func _build_slots() -> void:
	for child in slots.get_children():
		child.queue_free()
	var shown := _shown_ingredients()
	# Ein leeres Feld mehr, solange noch etwas hineinpasst.
	var visible_count := shown.size() if is_locked() else mini(shown.size() + 1, Brewing.capacity)
	for i in visible_count:
		var slot: BrewSlot = SLOT_SCENE.instantiate()
		slot.index = i
		slot.window = self
		slot.position = _slot_position(i, visible_count)
		slots.add_child(slot)
		if i < shown.size():
			slot.show_ingredient(Inventory.icon_for(shown[i]))


## Felder im flachen Bogen über dem Kessel, außen etwas tiefer.
func _slot_position(i: int, count: int) -> Vector2:
	var offset := i - (count - 1) / 2.0
	var x := roundi(CAULDRON_CENTER_X + offset * SLOT_SPACING) - 10
	var y := SLOT_BASE_Y + roundi(offset * offset * 3)
	return Vector2(x, y)


## Rauten unter dem Kessel: belegt / frei.
func _build_pips() -> void:
	for child in pips.get_children():
		child.queue_free()
	var start_x := CAULDRON_CENTER_X - (Brewing.capacity * PIP_SPACING - 2) / 2
	for i in Brewing.capacity:
		var pip := TextureRect.new()
		pip.texture = PIP if i < _shown_ingredients().size() else PIP_EMPTY
		pip.position = Vector2(start_x + i * PIP_SPACING, PIP_Y)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)


## Gepunktete Trennlinie zwischen Kessel und Inventar, wie im Mockup.
func _build_divider() -> void:
	var image := Image.create(int(divider.size.x), 1, false, Image.FORMAT_RGBA8)
	for x in image.get_width():
		image.set_pixel(x, 0, Color("#8A5240") if x % 4 == 0 else Color("#4D1230"))
	divider.texture = ImageTexture.create_from_image(image)
