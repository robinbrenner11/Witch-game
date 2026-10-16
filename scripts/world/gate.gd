@tool
class_name Gate
extends StaticBody2D

## Eine Sperre in der Welt, die man sieht, bevor man sie öffnen kann
## (docs/design/welt_und_items.md, Abschnitt 4). Solange sie zu ist,
## blockiert sie den Weg und meldet beim Anlaufen locked_message.
##
## Sie ist offen, sobald EINE ihrer Bedingungen erfüllt ist:
##   required_flag   Flag in WorldState gesetzt (wie bei Exit). Wird ein Gate
##                   mit einem Trank geöffnet, setzt es dieses Flag selbst,
##                   dann bleibt es für immer offen.
##   moon_phase      gerade diese Mondphase (Moon.Phase), -1 = egal
##   active_effects  eine dieser Trankwirkungen ist aktiv ("wisp", "moonlight")
##   open_with_item  dieser Trank wird daraufgegossen (E) oder geworfen
##
## Aussehen: optionale Kind-Nodes "Closed" und "Open" werden je nach Zustand
## ein- und ausgeblendet. So kann später eine Grafik an dieselbe Stelle.

signal opened

const EDITOR_COLOR := Color("#D9A441")
# Die Hexe liegt auf Physik-Layer 1. Klippen-Layer 4 (Bit 8), damit auch
# Käfer und NPCs nicht durchkommen, aber Zauber darüberfliegen.
const PLAYER_LAYER := 1
const CLIFF_LAYER := 8
# So oft höchstens kommt die Meldung, wenn man dagegenläuft.
const MESSAGE_COOLDOWN := 2.0

## Größe des Hindernisses in Pixeln, Mitte = Ursprung.
@export var size: Vector2 = Vector2(64, 32):
	set(value):
		size = value
		queue_redraw()
@export var required_flag: String = ""
## Moon.Phase (0 Neumond … 4 Vollmond), -1 = keine Mondbedingung.
@export var moon_phase: int = -1
@export var active_effects: Array[String] = []
## Item-ID eines Tranks zum Gießen oder Werfen. Braucht required_flag.
@export var open_with_item: String = ""
## Meldung, solange zu (Text-Schlüssel).
@export var locked_message: String = "MSG_PATH_LOCKED"
## Was E zeigt, wenn man den passenden Trank nicht in der Hand hat
## (Text-Schlüssel, leer = keine Interaktion).
@export var look_message: String = ""

var _open := false
var _message_wait := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("potion_target")
	collision_layer = CLIFF_LAYER
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	add_child(_shape)
	_add_sensor()
	if look_message != "" or open_with_item != "":
		_add_interactable()
	if open_with_item != "" and required_flag == "":
		push_warning("Gate %s: open_with_item braucht ein required_flag" % name)
	_apply(is_open(), true)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_message_wait = maxf(_message_wait - delta, 0.0)
	var now := is_open()
	if now != _open:
		_apply(now, false)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(-size / 2, size), EDITOR_COLOR, false)


func is_open() -> bool:
	if required_flag != "" and WorldState.has_flag(required_flag):
		return true
	if moon_phase >= 0 and Moon.phase() == moon_phase:
		return true
	for effect in active_effects:
		if _effect_active(effect):
			return true
	return false


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	if _open:
		return ""
	if open_with_item != "" and Inventory.selected_item_id() == open_with_item:
		return "PROMPT_POUR"
	return "PROMPT_LOOK" if look_message != "" else ""


## Ein geworfener Trank ist hier gelandet (ThrownPotion ruft das für alles in
## der Gruppe "potion_target" in seinem Wirkkreis auf).
func on_potion(item: ItemData) -> bool:
	if _open or item == null or item.id != open_with_item:
		return false
	_open_for_good()
	return true


func _effect_active(effect: String) -> bool:
	var player := get_tree().get_first_node_in_group("player")
	var effects := player.get_node_or_null("PotionEffects") as PotionEffects if player else null
	return effects != null and effects.is_active(effect)


func _open_for_good() -> void:
	WorldState.set_flag(required_flag)
	_apply(true, false)


func _apply(open: bool, instant: bool) -> void:
	var was_open := _open
	_open = open
	_shape.set_deferred("disabled", open)
	var closed_node := get_node_or_null("Closed") as CanvasItem
	var open_node := get_node_or_null("Open") as CanvasItem
	if closed_node:
		closed_node.visible = not open
	if open_node:
		open_node.visible = open
	if open and not was_open and not instant:
		Sfx.play_at("garden/grow_magic", global_position)
		opened.emit()


## Etwas größer als das Hindernis: merkt, wenn die Hexe dagegenläuft.
func _add_sensor() -> void:
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size + Vector2(8, 8)
	shape.shape = rect
	sensor.add_child(shape)
	sensor.body_entered.connect(_on_body_touched)
	add_child(sensor)


func _add_interactable() -> void:
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size + Vector2(16, 16)
	shape.shape = rect
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)


func _on_body_touched(body: Node2D) -> void:
	if body is Player and not _open and _message_wait <= 0.0:
		_message_wait = MESSAGE_COOLDOWN
		Messages.deny(tr(locked_message))


func _on_interacted(player: Node2D) -> void:
	if _open:
		return
	var item := ItemData.from_id(Inventory.selected_item_id())
	if item and item.id == open_with_item and item.use == ItemData.Use.POUR:
		Inventory.remove(item.id)
		(player as Player).play_action("pour")
		Sfx.play_at("garden/pour", global_position)
		_open_for_good()
	elif look_message != "":
		Messages.post(tr(look_message))
