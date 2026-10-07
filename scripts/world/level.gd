class_name Level
extends Node2D

## Ein Ort der Welt (Unterschlupf, Garten, Wald). Main lädt immer genau einen
## davon und setzt die Hexe in dessen Objects-Node. Was über den Ort hinaus
## Bestand haben muss (Pflanzen, Kessel, Inventar), liegt in Autoloads – der
## Ort zeigt es nur an.
##
## Aufbau: Ground (TileMapLayer), Objects (Y-sortiert) und beliebig viele
## Exits (Ausgänge in andere Orte).

@onready var ground: TileMapLayer = $Ground
@onready var objects: Node2D = $Objects


func _ready() -> void:
	_build_bounds()


## Die bemalte Fläche in Pixeln. Daraus folgen Kameragrenzen und Wände, so
## wachsen beide automatisch mit, wenn man die Karte größer malt.
func pixel_rect() -> Rect2:
	var used := ground.get_used_rect()
	var tile_size := Vector2(ground.tile_set.tile_size)
	return Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)


## Die Kamera soll nie über den Kartenrand hinaus zeigen.
func apply_camera_limits(camera: Camera2D) -> void:
	var rect := pixel_rect()
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)


## Ausgang mit diesem Namen, oder null.
func find_exit(exit_name: String) -> Exit:
	return find_child(exit_name, true, false) as Exit


## Unsichtbare Wände am Kartenrand. WorldBoundaryShape2D ist eine unendlich
## lange Linie, hinter die nichts gelangt; je eine pro Seite.
func _build_bounds() -> void:
	var rect := pixel_rect()
	var bounds := StaticBody2D.new()
	bounds.name = "Bounds"
	add_child(bounds)
	var sides := [
		[Vector2(0, 1), Vector2(0, rect.position.y)],
		[Vector2(0, -1), Vector2(0, rect.end.y)],
		[Vector2(1, 0), Vector2(rect.position.x, 0)],
		[Vector2(-1, 0), Vector2(rect.end.x, 0)],
	]
	for side in sides:
		var boundary := WorldBoundaryShape2D.new()
		boundary.normal = side[0]
		var shape := CollisionShape2D.new()
		shape.shape = boundary
		shape.position = side[1]
		bounds.add_child(shape)
