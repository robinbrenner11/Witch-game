class_name Level
extends Node2D

## Ein Ort der Welt (Unterschlupf, Garten, Wald). Main lädt immer genau einen
## davon und setzt die Hexe in dessen Objects-Node. Was über den Ort hinaus
## Bestand haben muss (Pflanzen, Kessel, Inventar), liegt in Autoloads – der
## Ort zeigt es nur an.
##
## Aufbau: Ground (TileMapLayer), Objects (Y-sortiert) und beliebig viele
## Exits (Ausgänge in andere Orte).

# Terrain-Nummern der Erde im TileSet, auf der Beete gehen: die alte Erde
# (soil 1) und die Gartenerde (earth 6, Böden v2).
const SOIL_TERRAINS: Array[int] = [1, 6]
# Welcher Schritt-Sound (assets/audio/sfx/player/step_<name>) zu welchem
# Terrain im TileSet gehört. Waldboden mit Laub raschelt wie Gras.
const STEP_SURFACES := {
	0: "grass", 1: "soil", 2: "path", 3: "stone", 4: "stone",
	5: "grass", 6: "soil", 7: "grass", 8: "grass",
}

# Darf man hier mit einem Schnippen Beete anlegen? Nur im Garten.
@export var allows_beds: bool = false
# Sichere Zone (Garten, Unterschlupf): Hier bleibt Digitalis ruhig, kein Kampf.
@export var safe_zone: bool = false
# Nur in diesem Bereich (Pixel), im Garten innerhalb des Zauns. Leer = überall.
@export var bed_area: Rect2 = Rect2()
# So viele Pixel am unteren Kartenrand sieht man, kann sie aber nicht
# betreten. Dort liegt die Hotbar über dem Bild, also soll dort nichts
# Wichtiges sein. Die Wand steht entsprechend höher.
@export var hud_margin_bottom: float = 0.0
# Für Orte ohne Kachelboden (Innenräume aus einer Raumgrafik): Diese Fläche
# gilt dann für Kamera und Ränder. Leer = die bemalte Fläche zählt.
@export var fixed_rect: Rect2 = Rect2()
# Atmo-Loop dieses Orts (ID unter assets/audio/sfx/), z. B. "world/night_ambience_loop".
@export var ambience: String = ""
# Schritt-Sound, wo kein Kachelboden liegt (Innenräume aus einer Raumgrafik).
@export var step_surface_fallback: String = "stone"

@onready var ground: TileMapLayer = $Ground
@onready var objects: Node2D = $Objects


func _ready() -> void:
	# Über die Gruppe finden z. B. die Zauber der Hexe den aktuellen Ort.
	add_to_group("level")
	_build_bounds()
	Sfx.set_ambience(ambience)


## Darf hier ein Beet entstehen? Nur wo der Ort es erlaubt, im Beet-Bereich
## und auf reiner Erde.
func allows_bed_at(cell: Vector2i) -> bool:
	var center := Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0
	if bed_area.has_area() and not bed_area.has_point(center):
		return false
	return allows_beds and is_soil(cell)


## Liegt an dieser Zelle reine Erde? Bei Ecken-Terrains heißt das: alle vier
## Ecken des Tiles gehören zur Erde, Übergänge zu Gras oder Weg zählen nicht.
func is_soil(cell: Vector2i) -> bool:
	var data := ground.get_cell_tile_data(cell)
	if data == null or data.terrain_set != 0:
		return false
	for corner in [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER]:
		if data.get_terrain_peering_bit(corner) not in SOIL_TERRAINS:
			return false
	return true


## Worauf die Hexe hier gerade tritt: "grass", "soil", "path" oder "stone".
## Bei Übergangs-Tiles zählt die Ecke des Tiles, die dem Fuß am nächsten ist.
func step_surface_at(world_position: Vector2) -> String:
	var local := ground.to_local(world_position)
	var cell := ground.local_to_map(local)
	var data := ground.get_cell_tile_data(cell)
	if data == null or data.terrain_set != 0:
		return step_surface_fallback
	# map_to_local liefert die Mitte des Tiles, also sagt das Vorzeichen, in
	# welchem Viertel der Fuß steht.
	var offset := local - ground.map_to_local(cell)
	var corner: TileSet.CellNeighbor
	if offset.y < 0:
		corner = TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER if offset.x < 0 else TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
	else:
		corner = TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER if offset.x < 0 else TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER
	var terrain := data.get_terrain_peering_bit(corner)
	if terrain < 0:
		terrain = data.terrain
	return STEP_SURFACES.get(terrain, step_surface_fallback)


## Die bemalte Fläche in Pixeln. Daraus folgen Kameragrenzen und Wände, so
## wachsen beide automatisch mit, wenn man die Karte größer malt.
func pixel_rect() -> Rect2:
	if fixed_rect.has_area():
		return fixed_rect
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
		[Vector2(0, -1), Vector2(0, rect.end.y - hud_margin_bottom)],
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
