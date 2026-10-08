@tool
class_name Forage
extends Decor

## Etwas zum Sammeln in der Welt: Pilz, Beerenstrauch, Feder, Mondmoos.
## Die Hexe pflückt es mit E (harvest) und bekommt drop_item_id.
## Entweder ist es danach weg (Pilz, Feder) oder es bleibt gepflückt stehen
## und trägt später neu (Strauch nach ein paar Nächten, Moos zum Vollmond).
## Was wo wächst, steuert WildGrowth; der eigene Zustand liegt in Wilds.

## Kommt, wenn es eingesammelt und weg ist.
signal collected

@export var drop_item_id: String = ""
# Bild nach dem Pflücken. Leer = es verschwindet ganz.
@export var picked_texture: Texture2D
# Nur mit picked_texture: trägt nach so vielen Nächten wieder.
@export var regrow_nights: int = 0
# Nur bei Vollmond reif, und nur einmal pro Vollmond (Mondmoos).
@export var full_moon_only: bool = false
# Schlüssel der Meldung, wenn noch nichts zu holen ist (data/translations).
@export var not_ready_message: String = ""

# Setzt WildGrowth, damit der Zustand in Wilds gefunden wird.
var wild_place := ""
var wild_id := ""


func _ready() -> void:
	rustle_when_near = not Engine.is_editor_hint()
	super()
	if Engine.is_editor_hint():
		return
	var interactable := Interactable.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 16)
	shape.shape = rect
	interactable.position = Vector2(0, -8)
	interactable.add_child(shape)
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)
	# Der Tag kann auch vergehen, während man hier steht.
	DayCycle.day_passed.connect(_on_day_passed)
	# Erst nach dem Einsetzen kennt es seinen Platz in Wilds.
	_update_look.call_deferred()


func is_ripe() -> bool:
	if wild_id == "":
		return true
	var state := Wilds.item_state(wild_place, wild_id)
	if full_moon_only:
		return DayCycle.is_full_moon() and int(state.get("picked_cycle", -1)) != DayCycle.moon_cycle()
	return int(state.get("regrow_in", 0)) <= 0


func _on_interacted(player: Node2D) -> void:
	if not is_ripe():
		if not_ready_message != "":
			Messages.post(tr(not_ready_message))
		return
	if not Inventory.has_room_for(drop_item_id):
		Messages.post(tr("MSG_BAG_FULL"))
		return
	var witch := player as Player
	witch.play_action("harvest")
	await witch.wait_for_action_frame(2)
	Inventory.add(drop_item_id)
	if picked_texture == null:
		collected.emit()
		queue_free()
		return
	var state := Wilds.item_state(wild_place, wild_id)
	if full_moon_only:
		state["picked_cycle"] = DayCycle.moon_cycle()
	else:
		state["regrow_in"] = regrow_nights
	_update_look()


func _on_day_passed(_day: int) -> void:
	_update_look()


## Reif: das normale, glitzernde Bild. Gepflückt: das stille Ersatzbild,
## ohne Leuchten.
func _update_look() -> void:
	if sprite == null or picked_texture == null:
		return
	var ripe := is_ripe()
	var shown := texture if ripe else picked_texture
	sprite.sprite_frames = strip_frames(shown, frame_count if ripe else 1, fps)
	# Das Ersatzbild kann anders hoch sein, der Fuß bleibt unten.
	sprite.offset = Vector2(0, -shown.get_height() / 2.0)
	if ripe:
		sprite.play()
	if glow_sprite:
		glow_sprite.visible = ripe
