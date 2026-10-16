extends SceneTree

## Baut assets/environment/cliffs/cliff_tileset.tres aus den Atlanten und
## cliff_layout.json: je Material eine Atlas-Quelle (gleiches Raster) und die
## Kollisionsformen pro Feld auf dem Physik-Layer "cliffs".
##
## Nur nötig, wenn sich das Raster ändert (neue Felder). Übermalte Grafiken
## brauchen das nicht, die Datei zeigt einfach auf die PNGs.
##
## Aufruf (im Projektordner):
##   godot --headless --script res://tools/world_builder/make_cliff_tileset.gd

const CLIFF_DIR := "res://assets/environment/cliffs/"
const OUT := CLIFF_DIR + "cliff_tileset.tres"
# Physik-Layer 4 "cliffs" (Bit 8): Hexe, NPCs und Gegner prallen ab,
# Zauber fliegen darüber (Entscheidung 16.10.2026).
const CLIFF_LAYER_BIT := 8
# So dick sind die Kanten (Ränder ohne sichtbare Wand) in Pixeln.
const RIM := 6.0
# Reihenfolge = Quellen-ID im TileSet. Der Builder nutzt dieselbe Liste.
const MATERIALS := ["rock", "wall"]


func _initialize() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CLIFF_DIR + "cliff_layout.json"))
	var size := int(layout["tile_size"])
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(size, size)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, CLIFF_LAYER_BIT)
	tile_set.set_physics_layer_collision_mask(0, 0)
	for i in MATERIALS.size():
		var material: String = MATERIALS[i]
		var source := TileSetAtlasSource.new()
		source.texture = load(CLIFF_DIR + str(layout["materials"][material]))
		source.texture_region_size = Vector2i(size, size)
		tile_set.add_source(source, i)
		for tile_name in layout["tiles"]:
			var info: Dictionary = layout["tiles"][tile_name]
			var coords := Vector2i(int(info["col"]), int(info["row"]))
			source.create_tile(coords)
			var data := source.get_tile_data(coords, 0)
			for polygon in _collision_for(str(info["collision"]), size):
				var index := data.get_collision_polygons_count(0)
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, index, polygon)
	var error := ResourceSaver.save(tile_set, OUT)
	print("cliff_tileset: ", "gespeichert" if error == OK else "Fehler %d" % error)
	quit()


## Rechtecke als Polygone, Koordinaten relativ zur Kachelmitte (so erwartet
## Godot die Kollision im TileSet).
func _collision_for(kind: String, size: int) -> Array[PackedVector2Array]:
	var h := size / 2.0
	var result: Array[PackedVector2Array] = []
	match kind:
		"full":
			result.append(_rect(-h, -h, h, h))
		"rim_n":
			result.append(_rect(-h, -h, h, -h + RIM))
		"rim_e":
			result.append(_rect(h - RIM, -h, h, h))
		"rim_w":
			result.append(_rect(-h, -h, -h + RIM, h))
		"rim_ne":
			result.append(_rect(-h, -h, h, -h + RIM))
			result.append(_rect(h - RIM, -h + RIM, h, h))
		"rim_nw":
			result.append(_rect(-h, -h, h, -h + RIM))
			result.append(_rect(-h, -h + RIM, -h + RIM, h))
		"in_ne":
			result.append(_rect(h - RIM, -h, h, -h + RIM))
		"in_nw":
			result.append(_rect(-h, -h, -h + RIM, -h + RIM))
		"stair_l":
			result.append(_rect(-h, -h, -h + 4.0, h))
		"stair_r":
			result.append(_rect(h - 4.0, -h, h, h))
	return result


func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
