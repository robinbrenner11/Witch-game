@tool
class_name Lake
extends Node2D

## Platzhalter für einen See, solange es keine Wasser-Grafik gibt. Die Fläche
## ist eine leicht unregelmäßige Ellipse aus 4×4-Pixel-Blöcken: so bleiben die
## Kanten pixelig wie der Rest des Spiels (keine glatten Schrägen). Außen ein
## hellerer Uferstreifen, innen tiefes Wasser, oben links eine Mondspiegelung,
## die bei Vollmond heller wird. Man kann nicht hineinlaufen.
##
## @tool: Der See ist auch im Editor zu sehen, damit man ihn platzieren kann.
## Der Ursprung ist die Mitte des Sees.

const BLOCK := 4
const SHALLOW := Color("#26365E")
const DEEP := Color("#141B3A")
const REFLECTION := Color("#EADFCB")

## Größe in Pixeln (Breite, Höhe der Ellipse).
@export var size: Vector2 = Vector2(384, 288):
	set(value):
		size = value
		queue_redraw()
## Wie stark das Ufer von der glatten Ellipse abweicht (0 = glatt).
@export_range(0.0, 0.4) var wobble: float = 0.12:
	set(value):
		wobble = value
		queue_redraw()
## Anderer Wert = andere Uferform.
@export var seed_value: int = 3:
	set(value):
		seed_value = value
		queue_redraw()

var _reflection_alpha := 0.18


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build_collision()
	Moon.phase_changed.connect(func(_phase: int) -> void: _update_reflection())
	_update_reflection()


func _draw() -> void:
	_draw_area(1.0, SHALLOW)
	_draw_area(0.82, DEEP)
	# Mondspiegelung: ein schmaler heller Fleck oben links (Licht von oben links).
	var glint := Color(REFLECTION, _reflection_alpha)
	var center := Vector2(-size.x * 0.18, -size.y * 0.2)
	for row in range(-2, 3):
		var half := (3 - absi(row)) * 2 * BLOCK
		var y := center.y + row * BLOCK
		draw_rect(Rect2(Vector2(center.x - half, y).snapped(Vector2.ONE * BLOCK), Vector2(half * 2, BLOCK)), glint)


## Bei Vollmond ist die Spiegelung deutlich, bei Neumond kaum zu sehen.
func _update_reflection() -> void:
	_reflection_alpha = lerpf(0.06, 0.35, Moon.brightness())
	queue_redraw()


## Malt die Fläche (auf scale verkleinert) zeilenweise aus Blöcken.
func _draw_area(scale_factor: float, color: Color) -> void:
	for run in _runs(scale_factor, BLOCK):
		draw_rect(run, color)


## Nicht ganz bis zum Ufer, damit die Hexe am Rand stehen kann.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Water"
	for run in _runs(0.92, BLOCK * 2):
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = run.size
		shape.shape = rect
		shape.position = run.get_center()
		body.add_child(shape)
	add_child(body)


## Waagerechte Streifen (je eine Zeile der Höhe step), die zusammen die
## Seefläche ergeben. Ein Punkt ist drin, wenn er in der welligen Ellipse liegt.
func _runs(scale_factor: float, step: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var half := size * 0.5 * scale_factor
	# Das wellige Ufer kann etwas über die Ellipse hinausragen.
	var reach := half * (1.0 + wobble)
	var rows := int(ceil(reach.y / step))
	var cols := int(ceil(reach.x / step))
	for row in range(-rows, rows):
		var y := (row + 0.5) * step
		var start := 0
		var open := false
		# Eine Spalte mehr, damit ein Streifen am rechten Rand auch endet.
		for col in range(-cols, cols + 1):
			var inside := col < cols and _inside(Vector2((col + 0.5) * step, y), half)
			if inside and not open:
				start = col
				open = true
			elif not inside and open:
				result.append(Rect2(start * step, row * step, (col - start) * step, step))
				open = false
	return result


func _inside(point: Vector2, half: Vector2) -> bool:
	var angle := point.angle()
	var edge := 1.0 + wobble * (sin(angle * 3.0 + seed_value) * 0.6 + sin(angle * 5.0 + seed_value * 2.3) * 0.4)
	var n := Vector2(point.x / half.x, point.y / half.y)
	return n.length() < edge
