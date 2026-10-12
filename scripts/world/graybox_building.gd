@tool
class_name GrayboxBuilding
extends Node2D

## Platzhalter für ein Gebäude, solange es noch keine Grafik gibt (Dorf-Graybox).
## Zeichnet Dach, Wand, Tür und Fenster als Farbflächen und bekommt eine
## Kollision an der Wand. Später ersetzt eine Decor-Szene mit Bild diesen
## Baustein an derselben Stelle.
##
## Wie bei Decor ist der Ursprung der Fußpunkt (unten Mitte). So stellt die
## Y-Sortierung die Hexe davor oder dahinter. Nur die Wand blockiert: Hinter
## dem Haus (nördlich) kann sie laufen, dann verdeckt das Dach sie.
##
## @tool: Das Script läuft auch im Editor, damit man das Haus beim Platzieren
## sieht und Größe, Tür und Fenster im Inspector einstellen kann.

const TILE := 32
const OUTLINE := Color("#2B1633")
const DOOR_COLOR := Color("#1C0F22")
const LIGHT_TEXTURE := preload("res://assets/effects/lights/light_round_64.png")
const WINDOW_SIZE := Vector2(10, 12)
const DOOR_SIZE := Vector2(16, 24)

## Gesamtgröße in Kacheln (Breite, Höhe mit Dach).
@export var size_tiles: Vector2i = Vector2i(5, 5):
	set(value):
		size_tiles = value
		_rebuild()
## So viele Kachelreihen oben sind Dach.
@export var roof_rows: int = 2:
	set(value):
		roof_rows = value
		_rebuild()
@export var wall_color: Color = Color("#5A3F63"):
	set(value):
		wall_color = value
		queue_redraw()
@export var roof_color: Color = Color("#6E1830"):
	set(value):
		roof_color = value
		queue_redraw()
## Spalte der Tür (0 = ganz links), -1 = keine Tür.
@export var door_column: int = 2:
	set(value):
		door_column = value
		queue_redraw()
## Spalten mit Fenster.
@export var window_columns: PackedInt32Array = PackedInt32Array([1, 3]):
	set(value):
		window_columns = value
		_rebuild()
## Brennt nachts Licht hinter den Fenstern? Leerstehende Häuser: aus.
@export var lit: bool = true:
	set(value):
		lit = value
		_rebuild()
@export var window_light_energy: float = 0.7

var _built := false


func _ready() -> void:
	_built = true
	_rebuild()


## Fenster und Kollision sind eigene Nodes (Fenster leuchten, also unbeleuchtet
## gezeichnet, und brauchen ein Licht). Sie entstehen hier neu, wenn sich im
## Inspector etwas ändert. Gespeichert werden sie nicht, wie bei Decor.
func _rebuild() -> void:
	if not _built:
		return
	for child in get_children():
		child.queue_free()
	_add_collision()
	for column in window_columns:
		_add_window(column)
	queue_redraw()


func _draw() -> void:
	var width := size_tiles.x * TILE
	var height := size_tiles.y * TILE
	var roof_height := roof_rows * TILE
	var top_left := Vector2(-width / 2.0, -height)
	draw_rect(Rect2(top_left, Vector2(width, roof_height)), roof_color)
	# Dachkante: dunkler Streifen, damit Dach und Wand sich trennen.
	draw_rect(Rect2(top_left + Vector2(0, roof_height - 4), Vector2(width, 4)), roof_color.darkened(0.35))
	draw_rect(Rect2(top_left + Vector2(0, roof_height), Vector2(width, height - roof_height)), wall_color)
	if door_column >= 0:
		var door_x := _column_center(door_column) - DOOR_SIZE.x / 2.0
		draw_rect(Rect2(Vector2(door_x, -DOOR_SIZE.y), DOOR_SIZE), DOOR_COLOR)
	draw_rect(Rect2(top_left, Vector2(width, height)), OUTLINE, false, 1.0)


func _add_collision() -> void:
	var wall_height := (size_tiles.y - roof_rows) * TILE
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size_tiles.x * TILE, wall_height)
	shape.shape = rect
	shape.position = Vector2(0, -wall_height / 2.0)
	body.add_child(shape)
	add_child(body)


func _add_window(column: int) -> void:
	var wall_height := (size_tiles.y - roof_rows) * TILE
	var window := ColorRect.new()
	window.size = WINDOW_SIZE
	window.position = Vector2(_column_center(column) - WINDOW_SIZE.x / 2.0, -wall_height + 14)
	window.color = Color("#FFB566") if lit else Color("#1C0F22")
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if lit:
		# Unbeleuchtet: Das Fenster selbst leuchtet, auch in tiefer Nacht.
		var glow := CanvasItemMaterial.new()
		glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		window.material = glow
	add_child(window)
	if lit and not Engine.is_editor_hint():
		var light := NightLight.new()
		light.texture = LIGHT_TEXTURE
		light.texture_scale = 1.0
		light.color = Color("#FFB566")
		light.base_energy = window_light_energy
		light.flicker = 0.05
		light.position = window.position + WINDOW_SIZE / 2.0 + Vector2(0, 10)
		add_child(light)


func _column_center(column: int) -> float:
	return (column + 0.5) * TILE - size_tiles.x * TILE / 2.0
