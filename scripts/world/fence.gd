class_name Fence
extends TileMapLayer

## Zaun als eigene Kachel-Ebene. Gemalt wird mit irgendeiner Zaunkachel; beim
## Start sucht sich jede Zelle selbst die passende Kachel aus ihren Nachbarn
## (Autotile) und bekommt eine schmale Kollision am Pfostenfuß.
## Gartentore (Gruppe "fence_gate") zählen dabei als Zaun, damit die Riegel
## an den Torpfosten enden. Siehe docs/ASSETS.md, Abschnitt Zaun.

# Kachel-Index = links·1 + rechts·2 + oben·4 + unten·8; Kachel in Spalte
# index % 4, Zeile index / 4.
const NEIGHBOR_BITS := {
	Vector2i.LEFT: 1,
	Vector2i.RIGHT: 2,
	Vector2i.UP: 4,
	Vector2i.DOWN: 8,
}
# Pfostenfuß und Riegel liegen unten in der Kachel (Fuß bei y = 28).
const FOOT_Y := 12.0
const BAR_THICKNESS := 6.0


func _ready() -> void:
	var cells := get_used_cells()
	var gate_cells := _gate_cells()
	var body := StaticBody2D.new()
	add_child(body)
	for cell in cells:
		var index := 0
		for offset: Vector2i in NEIGHBOR_BITS:
			var neighbor := cell + offset
			if get_cell_source_id(neighbor) != -1 or gate_cells.has(neighbor):
				index += NEIGHBOR_BITS[offset]
		set_cell(cell, 0, Vector2i(index % 4, index / 4))
		_add_collision(body, cell, index)


## Ein Streifen am Pfostenfuß, der in jede Richtung bis zum Kachelrand reicht,
## in der ein Nachbar steht. Angaben relativ zur Kachelmitte.
func _add_collision(body: StaticBody2D, cell: Vector2i, index: int) -> void:
	var half := tile_set.tile_size.x / 2.0
	var side := BAR_THICKNESS / 2.0
	var left := -half if index & 1 else -side
	var right := half if index & 2 else side
	var top := -half if index & 4 else FOOT_Y - BAR_THICKNESS
	var bottom := half if index & 8 else FOOT_Y
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, bottom - top)
	shape.shape = rect
	shape.position = map_to_local(cell) + Vector2(left + right, top + bottom) / 2.0
	body.add_child(shape)


func _gate_cells() -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for gate in get_tree().get_nodes_in_group("fence_gate"):
		# Tore stehen mit ihrem Fußpunkt in der Kachel, die sie ersetzen.
		result[local_to_map(to_local(gate.global_position))] = true
	return result
