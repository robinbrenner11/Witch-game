class_name CombatFx
extends RefCounted

## Kleine Kampfeffekte als Bausteine, damit Zauber, Hiebe, Tränke und Gegner
## gleich aussehen: Funken, ein sich ausbreitender Ring (Flächentreffer), ein
## Nachbild (Ausweichen). Alles leuchtet unbeleuchtet durch die Nacht und
## räumt sich selbst weg. (Platzhalter-Zeichnungen, bis es Grafiken gibt.)
##
## Benutzung: CombatFx.sparks(level.objects, position, farbe)
## oder ein Ring: parent.add_child(CombatFx.Ring.new(radius, farbe)).


## Ein kurzer Funkenregen an einer Stelle (Treffer, Heilung, Formwechsel).
static func sparks(parent: Node, at: Vector2, color: Color, amount: int = 10, speed: float = 45.0,
		gravity: float = 40.0) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = amount
	particles.lifetime = 0.4
	particles.spread = 180.0
	particles.gravity = Vector2(0, gravity)
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.color = color
	particles.material = unshaded()
	particles.z_index = 4
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func unshaded() -> CanvasItemMaterial:
	var material_unshaded := CanvasItemMaterial.new()
	material_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material_unshaded


## Ein Ring, der sich bis radius ausbreitet und verblasst: zeigt, wie weit ein
## Flächentreffer reicht (großer Zauber, Glutbombe).
class Ring:
	extends Node2D

	const TIME := 0.28

	var radius := 30.0
	var color := Color.WHITE
	var _time := 0.0

	func _init(ring_radius: float, ring_color: Color) -> void:
		radius = ring_radius
		color = ring_color

	func _ready() -> void:
		material = CombatFx.unshaded()
		z_index = 3

	func _process(delta: float) -> void:
		_time += delta
		if _time >= TIME:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_time / TIME, 0.0, 1.0)
		var r := roundf(lerpf(radius * 0.35, radius, sqrt(t)))
		var alpha := 1.0 - t
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color, alpha), 1.0)
		draw_arc(Vector2.ZERO, r - 2.0, 0.0, TAU, 40, Color(color, alpha * 0.4), 1.0)


## Ein Nachbild der Hexe beim Ausweichen: das aktuelle Bild in Magenta,
## blasst schnell aus.
class Afterimage:
	extends Sprite2D

	const TIME := 0.22

	var _time := 0.0

	func _init(source: AnimatedSprite2D) -> void:
		texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
		offset = source.offset
		flip_h = source.flip_h
		centered = source.centered
		modulate = Color(0.89, 0.35, 0.69, 0.55)

	func _ready() -> void:
		material = CombatFx.unshaded()
		z_index = -1

	func _process(delta: float) -> void:
		_time += delta
		modulate.a = 0.55 * (1.0 - _time / TIME)
		if _time >= TIME:
			queue_free()
