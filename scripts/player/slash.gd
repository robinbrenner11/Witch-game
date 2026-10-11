class_name Slash
extends Node2D

## Ein Hieb der Sichel: ein heller Bogen, der in Richtung Maus durchzieht und
## alles im Bogen einmal trifft. Getroffen wird nach Abstand und Winkel statt
## über Physik-Signale; so trifft jeder Hieb jedes Wesen genau einmal, egal
## wie viele Frames er dauert. Werte aus AttackData (data/digitalis/sickle.tres).
## Hängt am Ort, folgt aber der Hexe, solange er zu sehen ist.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)

# Mitte des Hiebs relativ zu den Füßen der Hexe (etwa Hüfthöhe).
const CENTER_OFFSET := Vector2(0, -20)
# Trefferpunkt eines Wesens relativ zu seinen Füßen und wie dick es ist.
const ENEMY_CENTER := Vector2(0, -8)
const ENEMY_RADIUS := 8.0
# Ganz nah zählt jeder Winkel (sonst könnte man an einem Käfer vorbeihauen,
# der einem auf den Füßen steht).
const POINT_BLANK := 12.0
const FADE_TIME := 0.12

var attack: AttackData
var aim := Vector2.RIGHT
var source: Player
# Schwung von links nach rechts oder umgekehrt; Combat wechselt bei leichten
# Hieben ab, damit Serien nicht gestempelt wirken.
var mirrored := false

var _time := 0.0
var _hit: Dictionary = {}


func _ready() -> void:
	material = CombatFx.unshaded()
	z_index = 3
	_follow()
	_check_hits()


func _process(delta: float) -> void:
	_time += delta
	_follow()
	if _time <= attack.active_time:
		_check_hits()
	elif _time >= attack.active_time + FADE_TIME:
		queue_free()
	queue_redraw()


func _follow() -> void:
	if is_instance_valid(source):
		global_position = (source.global_position + CENTER_OFFSET).round()


func _check_hits() -> void:
	for enemy in get_tree().get_nodes_in_group("blighted"):
		var id := enemy.get_instance_id()
		if _hit.has(id) or not enemy.has_method("take_hit"):
			continue
		var point: Vector2 = enemy.global_position + ENEMY_CENTER
		if _in_arc(point, ENEMY_RADIUS):
			_hit[id] = true
			var push := (point - global_position).normalized()
			enemy.take_hit(attack.damage, push * attack.knockback)
			CombatFx.sparks(get_parent(), point, attack.color, 8, 40.0)
	if attack.cuts_wild:
		for node in get_tree().get_nodes_in_group("wild"):
			if node is Weed and _in_arc((node as Node2D).global_position + Vector2(0, -6), 6.0):
				(node as Weed).cut()


func _in_arc(point: Vector2, extra: float) -> bool:
	var offset := point - global_position
	if offset.length() > attack.reach + extra:
		return false
	if offset.length() <= POINT_BLANK:
		return true
	return absf(aim.angle_to(offset)) <= deg_to_rad(attack.arc_degrees) / 2.0


## Ein Sichelmond aus mehreren Bögen: außen hell, innen schwächer. Der Bogen
## zieht in active_time durch und blasst danach aus.
func _draw() -> void:
	var half := deg_to_rad(attack.arc_degrees) / 2.0
	var sweep := clampf(_time / attack.active_time, 0.0, 1.0)
	var fade := 1.0 - clampf((_time - attack.active_time) / FADE_TIME, 0.0, 1.0)
	var start := aim.angle() + (half if mirrored else -half)
	var end := lerpf(start, aim.angle() + (-half if mirrored else half), sweep)
	if absf(end - start) < 0.01:
		return
	var points := maxi(6, int(absf(end - start) * 10.0))
	var reach := attack.reach
	draw_arc(Vector2.ZERO, reach, start, end, points, Color(attack.color, fade), 2.0)
	draw_arc(Vector2.ZERO, reach - 3.0, start, end, points, Color(attack.color, 0.6 * fade), 2.0)
	draw_arc(Vector2.ZERO, reach - 6.0, start, end, points, Color(attack.color, 0.25 * fade), 2.0)
	# Die Schneide: ein heller Punkt vorne am Bogen, solange er zieht.
	if sweep < 1.0:
		draw_rect(Rect2((Vector2.from_angle(end) * reach).round() - Vector2.ONE, Vector2(2, 2)), Color("#FFD2EC"))
