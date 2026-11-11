class_name BloomHazard
extends Node2D

## Ein Angriff des Blütenherzens auf dem Boden: erst eine deutliche Warnung
## (pulsierender Umriss, der sich füllt), dann schlägt er zu. Wer dann noch
## darin steht, nimmt Schaden. Kreis = Sporenplatzer, Strahl = Dornenreihe.
## (Angriffe kündigen sich sichtbar an, COMBAT_SYSTEM.md.)

enum Shape { CIRCLE, RAY }

const GROUP := "bloom_hazard"
const COLOR := Color("#C2307A")
const STRIKE_COLOR := Color("#FFD2EC")
const STRIKE_TIME := 0.18
# Die Hexe ist kein Punkt: etwas Spielraum an den Rändern.
const PLAYER_SLACK := 3.0

var shape := Shape.CIRCLE
var radius := 22.0
var direction := Vector2.RIGHT
var length := 220.0
var width := 16.0
var warn_time := 1.0
var damage := 1

var _time := 0.0
var _struck := false


func _ready() -> void:
	add_to_group(GROUP)
	# Flach auf dem Boden, unter Figuren.
	z_index = -4


func _process(delta: float) -> void:
	_time += delta
	if not _struck and _time >= warn_time:
		_strike()
	elif _struck and _time >= warn_time + STRIKE_TIME:
		queue_free()
	queue_redraw()


func covers(point: Vector2) -> bool:
	var local := point - global_position
	if shape == Shape.CIRCLE:
		return local.length() <= radius + PLAYER_SLACK
	var along := local.dot(direction)
	var across := absf(local.dot(direction.orthogonal()))
	return along >= 0.0 and along <= length and across <= width / 2.0 + PLAYER_SLACK


func _strike() -> void:
	_struck = true
	Sfx.play_at("combat/burst", global_position, -4.0)
	var center := global_position + (direction * length / 2.0 if shape == Shape.RAY else Vector2.ZERO)
	CombatFx.sparks(get_parent(), center, COLOR, 14 if shape == Shape.CIRCLE else 22, 60.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and covers(player.global_position):
		hurt(player, global_position, damage)


## Schaden an der Hexe wie bei einem Käfer-Treffer: kurz unverwundbar,
## ein kleiner Stoß weg, und sie zieht Digitalis.
static func hurt(player: Player, from: Vector2, amount: int) -> void:
	var vitals := player.get_node("Vitals") as Vitals
	if vitals.take_damage(amount):
		vitals.make_invulnerable(0.8)
		var away := (player.global_position - from).normalized()
		player.start_dash((away if away != Vector2.ZERO else Vector2.DOWN) * 200.0, 0.1)
		(player.get_node("Combat") as Combat).set_active(true)


func _draw() -> void:
	var progress := clampf(_time / warn_time, 0.0, 1.0)
	if _struck:
		_draw_shape(STRIKE_COLOR, 1.0, true)
		return
	# Umriss pulsiert schneller, je näher der Schlag; die Füllung wächst.
	var pulse := 0.55 + 0.45 * sin(_time * (8.0 + progress * 14.0))
	_draw_shape(COLOR, 0.25 + 0.5 * pulse, false)
	_draw_shape(COLOR, 0.12 + 0.28 * progress, true, progress)


func _draw_shape(color: Color, alpha: float, filled: bool, grow: float = 1.0) -> void:
	var c := Color(color, alpha)
	if shape == Shape.CIRCLE:
		if filled:
			draw_circle(Vector2.ZERO, radius * grow, c)
		else:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, c, 2.0)
		return
	var side := direction.orthogonal() * width / 2.0 * (grow if filled else 1.0)
	var tip := direction * length * (grow if filled else 1.0)
	var points := PackedVector2Array([side, tip + side, tip - side, -side])
	if filled:
		draw_colored_polygon(points, c)
	else:
		points.append(side)
		draw_polyline(points, c, 2.0)
