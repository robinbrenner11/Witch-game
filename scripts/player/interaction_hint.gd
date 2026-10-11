extends Node2D

## Goldene Eckklammern um das, womit E gerade interagieren würde (bei einem
## Beet genau um das Tile), und darüber eine kleine Plakette mit Taste und
## Tätigkeit, z. B. [E] Ernten. So sieht man, was gemeint ist und was passiert,
## bevor man drückt – und niemand legt sich aus Versehen schlafen.
##
## Die Größe kommt aus der Form des Interactables, der Text aus
## Interactable.prompt_key(), deshalb braucht kein Objekt eine eigene
## Einstellung für die Anzeige. Hängt unter dem Player, ist aber "top_level":
## Er bewegt sich nicht mit der Hexe, sondern wird jeden Frame aufs Ziel gesetzt.

const COLOR := Color("#D9A441")
# Plakette: Tiefschwarz, leicht durchscheinend, Text in Knochenweiß.
const PLATE_COLOR := Color(0.0549, 0.0392, 0.0784, 0.82)
const PLATE_EDGE := Color("#2B1633")
const TEXT_COLOR := Color("#EADFCB")
const FONT := preload("res://assets/ui/fonts/game_font.tres")
# Normale Pixelgröße der Schrift (wie im Grimoire), in Welt-Pixeln.
const FONT_SIZE := 16
const PLATE_HEIGHT := 13
const BASELINE := 10
const PADDING := 3
const KEY_GAP := 4
# Länge der Klammer-Arme in Pixeln.
const ARM := 4
# Abstand der Plakette über den Klammern.
const PROMPT_GAP := 3
# So schnell blendet die Plakette ein (Sekunden), damit sie beim Vorbeilaufen
# nicht hart aufblitzt.
const FADE_IN := 0.12

var _rect := Rect2()
var _time := 0.0
# Worauf der Hinweis gerade zeigt (ein Interactable oder eine Beet-Zelle).
# Wechselt es, blendet die Plakette neu ein.
var _target_id: Variant = null
var _prompt := ""
var _key := ""
var _prompt_alpha := 0.0

@onready var player: Player = get_parent()
@onready var earth_magic: Node = player.get_node("EarthMagic")


# Bei offenen Fenstern (Spiel pausiert) läuft _process nicht weiter; ohne das
# hier blieben Klammern und Plakette über dem Fenster stehen.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		hide()
		_target_id = null


func _process(delta: float) -> void:
	# Beim Schlafen ist die Steuerung und damit auch der Hinweis aus.
	var active := player.can_act() and not player.combat_mode
	var target := player.find_closest_interactable() if active else null
	var target_id: Variant = null
	var rect := Rect2()
	var prompt_key := ""
	var key_action := "interact"
	if target:
		target_id = target
		rect = _target_rect(target)
		# Jeden Frame neu, weil der Text vom Zustand abhängt (Item in der
		# Hand, Pflanze reif geworden …).
		prompt_key = target.prompt_key()
	elif active and _wants_wake_hint():
		var cell := Garden.cell_at(player.interaction_area.global_position)
		target_id = cell
		rect = Rect2(Vector2(cell * Garden.TILE_SIZE), Vector2.ONE * Garden.TILE_SIZE)
		prompt_key = "PROMPT_WAKE"
		key_action = "snap"
	visible = target_id != null
	if not visible:
		_target_id = null
		return
	# Erst den Typ vergleichen: Interactable und Zelle lassen sich nicht
	# direkt miteinander vergleichen.
	if typeof(target_id) != typeof(_target_id) or target_id != _target_id:
		_target_id = target_id
		_prompt_alpha = 0.0
		_key = InputHints.key_for(key_action)
	_time += delta
	_prompt_alpha = minf(_prompt_alpha + delta / FADE_IN, 1.0)
	_prompt = tr(prompt_key) if prompt_key != "" else ""
	# Ein Pixel Atmen: Die Klammern gehen langsam etwas auseinander.
	var grow := 1.0 if sin(_time * 4.0) > 0.0 else 0.0
	_rect = rect.grow(grow)
	queue_redraw()


## Einmal-Hinweis fürs Beete-Anlegen: Samen in der Hand, vor der Hexe freie
## Gartenerde, und sie hat noch nie ein Beet geweckt. Nach dem ersten Mal
## (Grimoire-Ziel "wake") weiß man es und der Garten bleibt ruhig.
func _wants_wake_hint() -> bool:
	if Grimoire.is_goal_done("wake"):
		return false
	var item := ItemData.from_id(Inventory.selected_item_id())
	if item == null or item.type != ItemData.Type.SEED:
		return false
	return earth_magic.can_wake_at(Garden.cell_at(player.interaction_area.global_position))


func _draw() -> void:
	var left := _rect.position.x
	var top := _rect.position.y
	# Letzte Pixelspalte bzw. -zeile innerhalb des Rechtecks.
	var right := _rect.end.x - 1
	var bottom := _rect.end.y - 1
	# Je Ecke ein waagerechter und ein senkrechter Arm, nach innen zeigend.
	for corner: Vector2 in [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]:
		var arm_x := corner.x if corner.x == left else corner.x - ARM + 1
		var arm_y := corner.y if corner.y == top else corner.y - ARM + 1
		draw_rect(Rect2(arm_x, corner.y, ARM, 1), COLOR)
		draw_rect(Rect2(corner.x, arm_y, 1, ARM), COLOR)
	if _prompt != "":
		_draw_prompt()


## "E  Ernten": Taste in Gold (wie in der Bedienzeile des Grimoire), daneben
## die Tätigkeit in Knochenweiß, auf einer dunklen Plakette, damit es auch
## über hellen Lichtinseln lesbar bleibt. Steht über den Klammern, ganz oben
## am Bildrand stattdessen darunter.
func _draw_prompt() -> void:
	var key_width := FONT.get_string_size(_key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var text_width := FONT.get_string_size(_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var size := Vector2(PADDING + key_width + KEY_GAP + text_width + PADDING, PLATE_HEIGHT)
	var origin := Vector2(roundf(_rect.get_center().x - size.x / 2.0), _rect.position.y - PROMPT_GAP - size.y)
	if origin.y < _view_top() + 2:
		origin.y = _rect.end.y + PROMPT_GAP
	var alpha := _prompt_alpha
	var plate_color := Color(PLATE_COLOR, PLATE_COLOR.a * alpha)
	# Plakette mit abgeschnittenen Ecken (ein Pixel), wie die Fensterrahmen.
	var plate := Rect2(origin, size)
	draw_rect(Rect2(plate.position.x + 1, plate.position.y, plate.size.x - 2, plate.size.y), plate_color)
	draw_rect(Rect2(plate.position.x, plate.position.y + 1, 1, plate.size.y - 2), plate_color)
	draw_rect(Rect2(plate.end.x - 1, plate.position.y + 1, 1, plate.size.y - 2), plate_color)
	draw_rect(Rect2(plate.position.x + 1, plate.end.y - 1, plate.size.x - 2, 1), Color(PLATE_EDGE, alpha))
	var baseline := origin.y + BASELINE
	draw_string(FONT, Vector2(origin.x + PADDING, baseline), _key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(COLOR, alpha))
	draw_string(FONT, Vector2(origin.x + PADDING + key_width + KEY_GAP, baseline), _prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(TEXT_COLOR, alpha))


## Oberkante des sichtbaren Bildausschnitts in Weltkoordinaten.
func _view_top() -> float:
	return (get_viewport().get_canvas_transform().affine_inverse() * Vector2.ZERO).y


## Rechteck der ersten rechteckigen Kollisionsform des Interactables, in
## ganzen Welt-Pixeln.
func _target_rect(target: Interactable) -> Rect2:
	for child in target.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var size: Vector2 = child.shape.size
			var center: Vector2 = child.global_position
			return Rect2((center - size / 2).round(), size.round())
	return Rect2(target.global_position.round() - Vector2(8, 8), Vector2(16, 16))
