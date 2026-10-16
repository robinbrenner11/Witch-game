@tool
class_name Waterfall
extends Node2D

## Platzhalter für einen Wasserfall, bis es eine Grafik gibt: fallende Streifen
## aus 4×4-Pixel-Blöcken über einer Klippenwand, unten ein schäumendes Becken.
## Man hört ihn schon, bevor man ihn sieht (Loop wird mit Abstand leiser).
##
## Der Ursprung ist die Oberkante in der Mitte. Das Becken ist ein Hindernis;
## die Wand dahinter blockiert ohnehin (Klippen-Layer).

const BLOCK := 4
const DEEP := Color("#141B3A")
const MID := Color("#26365E")
const LIGHT := Color("#4E6A9A")
const FOAM := Color("#EADFCB")
# Weltlayer, wie Bäume und Steine.
const WORLD_LAYER := 1

## Breite und Fallhöhe in Pixeln (Fallhöhe = Höhe der Wand).
@export var size: Vector2 = Vector2(48, 128):
	set(value):
		size = value
		queue_redraw()
## Becken unter dem Fall: Breite, Höhe in Pixeln.
@export var pool_size: Vector2 = Vector2(80, 40):
	set(value):
		pool_size = value
		queue_redraw()
## So weit ist er zu hören (Pixel).
@export var sound_distance: float = 420.0

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_child(Sfx.make_loop_player("world/waterfall_loop", 0.0, sound_distance))
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = pool_size
	shape.shape = rect
	shape.position = Vector2(0, size.y + pool_size.y / 2.0)
	body.add_child(shape)
	add_child(body)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# 12 Bilder pro Sekunde, in ganzen Blöcken: bleibt pixelig statt fließend.
	var step := int(_time * 12.0)
	var half := size.x / 2.0
	for x in range(int(-half), int(half), BLOCK):
		var lane := int((x + half) / BLOCK)
		for y in range(0, int(size.y), BLOCK):
			var phase := (y / BLOCK - step - lane * 3) % 6
			var color := MID
			if phase == 0:
				color = FOAM if lane % 3 == 1 else LIGHT
			elif phase == 1 or lane == 0:
				color = LIGHT if lane != 0 else DEEP
			draw_rect(Rect2(x, y, BLOCK, BLOCK), color)
	_draw_pool(step)


func _draw_pool(step: int) -> void:
	var center := Vector2(0, size.y + pool_size.y / 2.0)
	var rx := pool_size.x / 2.0
	var ry := pool_size.y / 2.0
	for x in range(int(-rx), int(rx), BLOCK):
		for y in range(int(-ry), int(ry), BLOCK):
			var u := (x + BLOCK / 2.0) / rx
			var v := (y + BLOCK / 2.0) / ry
			var d := u * u + v * v
			if d > 1.0:
				continue
			var color := DEEP if d > 0.55 else MID
			# Schaum direkt unter dem Fall, flackert in Blöcken.
			if absf(x) < half_width() and y < 0 and (x / BLOCK + y / BLOCK + step) % 3 != 0:
				color = FOAM if (x / BLOCK + step) % 2 == 0 else LIGHT
			draw_rect(Rect2(center + Vector2(x, y), Vector2(BLOCK, BLOCK)), color)


func half_width() -> float:
	return size.x / 2.0 + BLOCK
