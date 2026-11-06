## Wasser-Animation: eingebaute Kachel-Animation im Wasser-TileSet. Frame k
## eines Felds liegt k * 4 Spalten weiter rechts (docs/art/cliff_generator/water.py),
## gesetzt wird im Ort nur Frame 0 (so wie bisher).
extends TestCase

const WATER_DIR := "res://assets/environment/water/"
const SCENES_WITH_WATER := ["res://scenes/world/lakewood.tscn", "res://scenes/world/swamp.tscn",
		"res://scenes/world/waterfall_cave.tscn", "res://scenes/world/test/height_test.tscn"]


func _layout() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(WATER_DIR + "water_layout.json"))


func _source() -> TileSetAtlasSource:
	var tile_set := load(WATER_DIR + "water_tileset.tres") as TileSet
	return tile_set.get_source(0) as TileSetAtlasSource


func test_every_tile_is_animated() -> void:
	var layout := _layout()
	var frames := int(layout["frames"])
	var tiles: Dictionary = layout["tiles"]
	var source := _source()
	var texture_width := source.texture.get_width()
	check(frames >= 3 and frames <= 4, "3–4 Frames (ist: %d)" % frames)
	for tile_name in tiles:
		var coords := Vector2i(int(tiles[tile_name]["col"]), int(tiles[tile_name]["row"]))
		check(source.has_tile(coords), "Feld %s fehlt" % tile_name)
		check_eq(source.get_tile_animation_frames_count(coords), frames, "Frames von %s" % tile_name)
		for frame in frames:
			var region := source.get_tile_texture_region(coords, frame)
			check_eq(region.position.x, float((coords.x + frame * tiles.size()) * 32), "%s Frame %d liegt im richtigen Block" % [tile_name, frame])
			check(region.end.x <= texture_width, "%s Frame %d liegt im Bild" % [tile_name, frame])


func test_frames_differ_and_loop() -> void:
	var source := _source()
	var image := source.texture.get_image()
	var frames := source.get_tile_animation_frames_count(Vector2i(0, 0))
	var seen := {}
	for frame in frames:
		var region := Rect2i(source.get_tile_texture_region(Vector2i(0, 0), frame))
		var data := image.get_region(region).get_data()
		check(not seen.has(data), "Frame %d sieht aus wie ein anderer" % frame)
		seen[data] = true


## Kollision bleibt wie vorher: tief und Ufer blockieren, flach und Durchgang nicht.
func test_collision_unchanged() -> void:
	var tiles: Dictionary = _layout()["tiles"]
	var source := _source()
	for tile_name in tiles:
		var coords := Vector2i(int(tiles[tile_name]["col"]), int(tiles[tile_name]["row"]))
		var blocks := source.get_tile_data(coords, 0).get_collision_polygons_count(0) > 0
		check_eq(blocks, str(tiles[tile_name]["collision"]) == "full", "Kollision von %s" % tile_name)


## Schon gebaute Orte zeigen auf Frame 0 der Felder, also auf gültige Kacheln.
func test_scenes_use_base_tiles() -> void:
	var source := _source()
	for path in SCENES_WITH_WATER:
		var level := (load(path) as PackedScene).instantiate()
		var water := level.get_node_or_null("Water") as TileMapLayer
		check(water != null, "%s hat eine Wasser-Ebene" % path.get_file())
		if water:
			if path.get_file() in ["lakewood.tscn", "swamp.tscn"]:
				check(water.get_used_cells().size() > 0, "%s hat Wasser" % path.get_file())
			for cell in water.get_used_cells():
				var coords := water.get_cell_atlas_coords(cell)
				if not source.has_tile(coords):
					check(false, "%s: Zelle %s zeigt auf keine Kachel (%s)" % [path.get_file(), cell, coords])
					break
		level.free()


## Der World-Builder setzt weiter nur Frame 0; die Animation kommt vom TileSet.
func test_builder_paints_animated_tiles() -> void:
	var builder := WorldBuilder.new()
	builder._size = Vector2i(5, 5)
	for x in 5:
		for y in 5:
			builder._water[Vector2i(x, y)] = "deep"
	builder._water.erase(Vector2i(0, 0))
	builder._water[Vector2i(4, 4)] = "shallow"
	var layer := TileMapLayer.new()
	layer.tile_set = load(WATER_DIR + "water_tileset.tres")
	builder._paint_water(layer)
	var tiles: Dictionary = _layout()["tiles"]
	var source := _source()
	check_eq(layer.get_cell_atlas_coords(Vector2i(2, 2)), Vector2i(int(tiles["deep"]["col"]), 0), "Mitte tief")
	check_eq(layer.get_cell_atlas_coords(Vector2i(1, 0)), Vector2i(int(tiles["shore"]["col"]), 0), "Neben Land Ufer")
	check_eq(layer.get_cell_atlas_coords(Vector2i(4, 4)), Vector2i(int(tiles["shallow"]["col"]), 0), "Flach bleibt flach")
	for cell in layer.get_used_cells():
		check(source.get_tile_animation_frames_count(layer.get_cell_atlas_coords(cell)) > 1, "Zelle %s ist animiert" % cell)
	layer.free()
