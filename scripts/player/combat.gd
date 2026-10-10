class_name Combat
extends Node2D

## Kampfmodus der Hexe (F): Sie zieht Digitalis, den Fingerhut-Stab, und
## zielt mit der Maus. Linksklick: Zauber zur Maus. Rechtsklick: großer
## Zauber, der im Umkreis platzt. Shift: kurzer Dash, kurz unverwundbar.
## Alles kostet Hexenkraft (Vitals). Im Kampfmodus ruhen Ernten, Ausgießen
## und Schnippen, damit nichts aus Versehen passiert; Trinken (Q) geht.
## Im Garten und im Unterschlupf (sichere Zonen) bleibt Digitalis ruhig.
## Eigener Node unter dem Player, damit player.gd klein bleibt.
## Design: docs/design/game_design.md, Abschnitt 7.
## (Die Zauber sind noch Platzhalter-Zeichnungen, bis es Grafiken gibt.)

signal mode_changed(active: bool)

const SPELL_COST := 1.0
const SPECIAL_COST := 3.0
const DASH_COST := 1.0
const SPELL_COOLDOWN := 0.3
const SPECIAL_COOLDOWN := 0.9
const DASH_COOLDOWN := 0.5
const DASH_SPEED := 420.0
const DASH_TIME := 0.14
# Nach dem Dash so lange unverwundbar (etwas länger als der Dash selbst).
const DASH_INVULNERABLE := 0.25
# Wo der Fuß von Digitalis steht, relativ zu den Füßen der Hexe. Der große
# Stab steht neben ihr (nie vor dem Gesicht) und schwebt 2 px über dem Boden,
# so enden Stab und Kopf auf gleicher Höhe. Werte aus docs/ASSETS.md.
const STAFF_FOOT := {
	Vector2.DOWN: Vector2(14, -2),
	Vector2.UP: Vector2(-12, -2),
	Vector2.RIGHT: Vector2(12, -2),
	Vector2.LEFT: Vector2(-12, -2),
}

var active := false

var _cooldown := 0.0
var _dash_cooldown := 0.0

var reticle: Reticle
var staff: Digitalis

@onready var player: Player = get_parent()
@onready var vitals: Vitals = $"../Vitals"


func _ready() -> void:
	reticle = Reticle.new()
	reticle.top_level = true
	reticle.z_index = 10
	reticle.visible = false
	add_child(reticle)
	staff = Digitalis.new()
	staff.visible = false
	add_child(staff)


func _unhandled_input(event: InputEvent) -> void:
	if not player.is_physics_processing():
		return
	if event.is_action_pressed("combat"):
		set_active(not active)
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_cast(false)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cast(true)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("float"):
		_dash()
		get_viewport().set_input_as_handled()


func set_active(value: bool) -> void:
	if value and _in_safe_zone():
		Messages.post(tr("MSG_SAFE_ZONE"))
		return
	if value == active:
		return
	active = value
	player.combat_mode = active
	reticle.visible = active
	staff.visible = active
	_place_staff()
	mode_changed.emit(active)


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	if not active:
		return
	# Wer den Garten betritt, steckt Digitalis weg.
	if _in_safe_zone():
		set_active(false)
		return
	# Im Kampf schaut die Hexe dorthin, wohin sie zielt.
	player.face_towards(_aim())
	reticle.global_position = get_global_mouse_position().round()
	reticle.queue_redraw()
	_place_staff()


## Stellt Digitalis je nach Blickrichtung neben die Hexe.
func _place_staff() -> void:
	staff.position = STAFF_FOOT[player.facing]
	staff.set_flipped(player.facing == Vector2.LEFT)
	# Den Stab hinter der Hexe zeichnen, wenn sie nach oben schaut.
	z_index = -1 if player.facing == Vector2.UP else 1


func _aim() -> Vector2:
	var aim := get_global_mouse_position() - (player.global_position + Vector2(0, -28))
	return aim.normalized() if aim.length() > 1.0 else Vector2.DOWN


func _cast(special: bool) -> void:
	if _cooldown > 0.0:
		return
	if not vitals.spend_power(SPECIAL_COST if special else SPELL_COST):
		Messages.post(tr("MSG_NO_POWER"))
		return
	_cooldown = SPECIAL_COOLDOWN if special else SPELL_COOLDOWN
	staff.attack()
	var spell := Spell.new()
	spell.direction = (get_global_mouse_position() - _tip_position()).normalized()
	if special:
		spell.speed = 150.0
		spell.max_distance = 140.0
		spell.radius = 5.0
		spell.damage = 2
		spell.burst_radius = 30.0
		spell.knockback = 140.0
	var level := get_tree().get_first_node_in_group("level") as Level
	level.objects.add_child(spell)
	spell.global_position = _tip_position()


func _dash() -> void:
	if _dash_cooldown > 0.0 or not vitals.spend_power(DASH_COST):
		return
	_dash_cooldown = DASH_COOLDOWN
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = _aim()
	player.start_dash(direction.normalized() * DASH_SPEED, DASH_TIME)
	vitals.make_invulnerable(DASH_INVULNERABLE)


func _in_safe_zone() -> bool:
	var level := get_tree().get_first_node_in_group("level") as Level
	return level == null or level.safe_zone


func _tip_position() -> Vector2:
	return staff.tip_position()


## Kleines Fadenkreuz an der Maus, solange Digitalis gezogen ist.
class Reticle:
	extends Node2D

	func _draw() -> void:
		for offset: Vector2 in [Vector2(-5, 0), Vector2(4, 0), Vector2(0, -5), Vector2(0, 4)]:
			var size := Vector2(2, 1) if offset.y == 0 else Vector2(1, 2)
			draw_rect(Rect2(offset, size), Spell.COLOR)
		draw_rect(Rect2(0, 0, 1, 1), Spell.CORE)
