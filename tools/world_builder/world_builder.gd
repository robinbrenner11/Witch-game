class_name WorldBuilder
extends RefCounted

## Baut einen Ort aus einem Bauplan: ein Ordner mit kleinen PNGs, in denen
## 1 Pixel = 1 Kachel ist (Robin malt sie in Aseprite). Erzeugt werden nur
## drei Teile der Szene, alles andere bleibt, wie es von Hand gebaut wurde:
##   Ground              Boden über die Terrains des Boden-TileSets
##   Water               Wasser (tiefes am Rand als Ufer)
##   Cliffs              Klippen, Mauern, Kanten, Treppen (neuer TileMapLayer)
##   Objects/Generated   Bäume, Laternen, Steine … an den Markierungen
##
## Bauplan-Ordner (tools/world_builder/plans/<ort>/):
##   plan.json     Zielszene und Einstellungen
##   height.png    Höhe als Grauwert: schwarz 0, grau 1, weiß 2
##   ground.png    Boden: Farben = Terrain-Farben im Boden-TileSet
##   material.png  (optional) deckende Pixel = Mauer statt Fels
##   water.png     (optional) Wasser: tief (blockiert), flach (begehbar),
##                 Durchgang (sieht tief aus, ist begehbar, z. B. unter einem Gate)
##   marks.png     (optional) einzelne Pixel: Treppe, Baum, Laterne …
##
## Höhe ist nur gemalt (wie in Stardew Valley): Oben und unten ist normaler
## Boden, dazwischen liegt eine Wand mit Kollision. Die Wand wird aus der
## Grundfläche des höheren Gebiets herausgeschnitten, an seinem Südrand.
## Nach Norden, Osten und Westen gibt es nur einen schmalen Rand.

const CLIFF_DIR := "res://assets/environment/cliffs/"
const CLIFF_TILESET := CLIFF_DIR + "cliff_tileset.tres"
const WATER_DIR := "res://assets/environment/water/"
const WATER_TILESET := WATER_DIR + "water_tileset.tres"
# Farben in water.png
const WATER_COLORS := {"deep": Color("#141B3A"), "shallow": Color("#26365E"), "pass": Color("#4E6A9A")}
# Gleiche Reihenfolge wie in make_cliff_tileset.gd: Index = Quellen-ID.
const MATERIALS := ["rock", "wall"]
const TILE := 32
const GROUND_TERRAIN_SET := 0
# Unter Treppen liegt Stein, damit die Schritte nach Stein klingen.
const STAIR_GROUND := "slab"
# Reihenfolge, in der sich Terrains an Ecken durchsetzen (plan.json kann das
# mit "ground_priority" ändern). Nicht genannte Terrains kommen zuletzt.
const DEFAULT_GROUND_PRIORITY := ["path", "slab", "cobble", "soil", "earth", "meadow", "grass", "graveyard", "forest_floor"]
const CORNERS := [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER]

# Markierungen in marks.png. Farbe -> Art. Bewusst wenige, klar
# unterscheidbare Farben aus der Palette.
const MARKS := {
	"stairs": Color("#D9A441"),
	"lantern": Color("#FFB566"),
	"tree": Color("#3F7D5A"),
	"willow": Color("#8DB580"),
	"bush": Color("#2E5E44"),
	"rock": Color("#EADFCB"),
}
# Was an einer Markierung entsteht. Mehrere Szenen = Zufall pro Kachel
# (aber jedes Mal gleich, damit Neu-Erzeugen nichts umwürfelt).
const MARK_SCENES := {
	"lantern": ["res://scenes/world/graybox/lantern.tscn"],
	"tree": ["res://scenes/world/decor/tree_fir.tscn", "res://scenes/world/decor/tree_oak.tscn",
			"res://scenes/world/decor/tree_elder.tscn"],
	"willow": ["res://scenes/world/decor/tree_willow.tscn"],
	"bush": ["res://scenes/world/decor/bush_1.tscn", "res://scenes/world/decor/bush_2.tscn",
			"res://scenes/world/decor/bush_lavender.tscn"],
	"rock": ["res://scenes/world/decor/rock_1.tscn", "res://scenes/world/decor/rock_2.tscn"],
}

var _plan_dir := ""
var _settings: Dictionary = {}
var _size := Vector2i.ZERO
var _height: Array[PackedInt32Array] = []
var _wall: Array[PackedByteArray] = []
var _marks: Dictionary[Vector2i, String] = {}
# Wasser: Zelle -> "deep", "shallow" oder "pass"
var _water: Dictionary[Vector2i, String] = {}
# Wand-Kacheln: Zelle -> {row, n, material, stair}
var _faces: Dictionary[Vector2i, Dictionary] = {}
var _tiles: Dictionary[Vector2i, Array] = {}  # Zelle -> [Material, Feldname]
var _layout: Dictionary = {}
var report: PackedStringArray = []
var _placed := 0


## Baut den Ort aus dem Bauplan-Ordner und speichert die Szene.
## Gibt OK oder einen Fehlercode zurück; Details stehen in report.
func build(plan_dir: String) -> Error:
	_plan_dir = plan_dir.trim_suffix("/") + "/"
	var json := FileAccess.get_file_as_string(_plan_dir + "plan.json")
	if json.is_empty():
		report.append("plan.json fehlt in " + _plan_dir)
		return ERR_FILE_NOT_FOUND
	_settings = JSON.parse_string(json)
	_layout = JSON.parse_string(FileAccess.get_file_as_string(CLIFF_DIR + "cliff_layout.json"))
	var error := _read_images()
	if error != OK:
		return error
	_find_faces()
	_find_stairs()
	_choose_cliff_tiles()

	var scene_path: String = _settings["scene"]
	# Mit Bearbeitungs-Zustand laden, sonst speichert pack() bei Unterszenen alle
	# Werte mit, statt nur die Änderungen (dann käme z. B. eine neue Baumgrafik
	# hier nicht mehr an).
	var root: Node = (load(scene_path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	_paint_ground(root.get_node("Ground") as TileMapLayer)
	_paint_water(_water_layer(root))
	_paint_cliffs(_cliff_layer(root))
	_paint_depth(_depth_layer(root))
	_place_marks(root)
	var packed := PackedScene.new()
	packed.pack(root)
	error = ResourceSaver.save(packed, scene_path)
	root.free()
	report.append("%s: %d × %d Kacheln, %d Wand-/Treppen-Kacheln, %d Klippen-Kacheln gesamt, %d Objekte" %
			[scene_path, _size.x, _size.y, _faces.size(), _tiles.size(), _placed])
	return error


# --- Bilder lesen -------------------------------------------------------------

func _load_image(file: String, required: bool) -> Image:
	var path := ProjectSettings.globalize_path(_plan_dir + file)
	if not FileAccess.file_exists(_plan_dir + file):
		if required:
			report.append("fehlt: " + file)
		return null
	var image := Image.load_from_file(path)
	if image and image.get_size() != _size and _size != Vector2i.ZERO:
		report.append("%s hat eine andere Größe als height.png, wird ignoriert" % file)
		return null
	return image


func _read_images() -> Error:
	var height_image := _load_image("height.png", true)
	if height_image == null:
		return ERR_FILE_NOT_FOUND
	_size = height_image.get_size()
	var levels := int(_settings.get("levels", 3))
	var default_level := int(_settings.get("default_level", 1))
	for x in _size.x:
		var column := PackedInt32Array()
		column.resize(_size.y)
		for y in _size.y:
			var c := height_image.get_pixel(x, y)
			column[y] = default_level if c.a < 0.5 else roundi(c.r * (levels - 1))
		_height.append(column)

	var material_image := _load_image("material.png", false)
	for x in _size.x:
		var column := PackedByteArray()
		column.resize(_size.y)
		for y in _size.y:
			column[y] = 1 if material_image and material_image.get_pixel(x, y).a > 0.5 else 0
		_wall.append(column)

	var water_image := _load_image("water.png", false)
	if water_image:
		for x in _size.x:
			for y in _size.y:
				var c := water_image.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var kind := ""
				for name in WATER_COLORS:
					var w: Color = WATER_COLORS[name]
					if absf(w.r - c.r) + absf(w.g - c.g) + absf(w.b - c.b) < 0.08:
						kind = name
				if kind == "":
					report.append("unbekannte Wasserfarbe %s bei %s" % [c.to_html(false), Vector2i(x, y)])
				else:
					_water[Vector2i(x, y)] = kind

	var marks_image := _load_image("marks.png", false)
	if marks_image:
		for x in _size.x:
			for y in _size.y:
				var c := marks_image.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var kind := _nearest_mark(c)
				if kind == "":
					report.append("unbekannte Markierung %s bei %s" % [c.to_html(false), Vector2i(x, y)])
				else:
					_marks[Vector2i(x, y)] = kind
	return OK


func _nearest_mark(c: Color) -> String:
	for kind in MARKS:
		var m: Color = MARKS[kind]
		if absf(m.r - c.r) + absf(m.g - c.g) + absf(m.b - c.b) < 0.08:
			return kind
	return ""


func height_at(cell: Vector2i) -> int:
	return _height[cell.x][cell.y]


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func _material_at(cell: Vector2i) -> String:
	return MATERIALS[_wall[cell.x][cell.y]]


## Ist der Nachbar tiefer? Außerhalb der Karte zählt als gleich hoch, damit am
## Kartenrand keine Klippe entsteht.
func _lower(cell: Vector2i, offset: Vector2i) -> bool:
	var other := cell + offset
	return _inside(other) and height_at(other) < height_at(cell)


# --- Wände und Treppen -------------------------------------------------------

## Jede Zelle, unter der es tiefer weitergeht, ist der Fuß einer Wand. Die Wand
## ist (Höhenunterschied × Reihen pro Stufe) Kacheln hoch und wird von dort
## nach oben in die höhere Fläche hineingeschnitten.
func _find_faces() -> void:
	var rows_per_level: Dictionary = _settings.get("rows_per_level", {"rock": 2, "wall": 1})
	for x in _size.x:
		for y in _size.y:
			var foot := Vector2i(x, y)
			if not _lower(foot, Vector2i.DOWN):
				continue
			var level := height_at(foot)
			var material := _material_at(foot)
			var wanted := (level - height_at(foot + Vector2i.DOWN)) * int(rows_per_level.get(material, 1))
			var rows := 0
			while rows < wanted:
				var cell := foot - Vector2i(0, rows)
				if not _inside(cell) or height_at(cell) != level or _faces.has(cell):
					break
				rows += 1
			if rows < wanted:
				report.append("Wand bei %s nur %d statt %d Reihen hoch (Fläche zu schmal)" % [foot, rows, wanted])
			for i in rows:
				_faces[foot - Vector2i(0, rows - 1 - i)] = {"row": i, "n": rows, "material": material, "stair": false}


## Eine Treppen-Markierung auf einer Wand macht die ganze Wand-Spalte an dieser
## Stelle zur Treppe.
func _find_stairs() -> void:
	for cell: Vector2i in _marks.keys():
		if _marks[cell] != "stairs":
			continue
		_marks.erase(cell)
		if not _faces.has(cell):
			report.append("Treppe bei %s liegt nicht auf einer Wand, wird ignoriert" % cell)
			continue
		var top := cell
		while _faces.has(top + Vector2i.UP) and _faces[top + Vector2i.UP]["n"] == _faces[cell]["n"] \
				and _faces[top]["row"] > 0:
			top += Vector2i.UP
		for i in int(_faces[top]["n"]):
			_faces[top + Vector2i(0, i)]["stair"] = true


func _is_stair(cell: Vector2i) -> bool:
	return _faces.has(cell) and _faces[cell]["stair"]


func _row_kind(face: Dictionary) -> String:
	var row: int = face["row"]
	var n: int = face["n"]
	if n == 1:
		return "single"
	if row == 0:
		return "top"
	return "bottom" if row == n - 1 else "mid"


# --- Kacheln wählen ----------------------------------------------------------

func _choose_cliff_tiles() -> void:
	for cell: Vector2i in _faces:
		var face := _faces[cell]
		var kind := _row_kind(face)
		if face["stair"]:
			var left := not _is_stair(cell + Vector2i.LEFT)
			var right := not _is_stair(cell + Vector2i.RIGHT)
			var side := "middle" if left == right else ("left" if left else "right")
			_tiles[cell] = [face["material"], "stair_%s_%s" % [kind, side]]
		else:
			_tiles[cell] = [face["material"], "face_%s_%s" % [kind, _face_end(cell)]]
	for x in _size.x:
		for y in _size.y:
			var cell := Vector2i(x, y)
			if _faces.has(cell):
				continue
			var rim := _rim_for(cell)
			if rim != "":
				_tiles[cell] = [_material_at(cell), rim]
	_add_shadows()


## Wie endet die Wand links und rechts? Weiter (Nachbar ist auch Wand oder
## Treppe), außen (daneben ist es tiefer) oder innen (daneben ragt die höhere
## Fläche weiter nach Süden).
func _face_end(cell: Vector2i) -> String:
	var left := _side(cell, Vector2i.LEFT)
	var right := _side(cell, Vector2i.RIGHT)
	if left == "cont" and right == "cont":
		return "middle"
	if left != "cont" and right != "cont":
		return "solo"
	if left != "cont":
		return "left_" + left
	return "right_" + right


func _side(cell: Vector2i, offset: Vector2i) -> String:
	var other := cell + offset
	if not _inside(other) or _faces.has(other):
		return "cont"
	return "outer" if height_at(other) < height_at(cell) else "inner"


func _rim_for(cell: Vector2i) -> String:
	var north := _lower(cell, Vector2i.UP)
	var east := _lower(cell, Vector2i.RIGHT)
	var west := _lower(cell, Vector2i.LEFT)
	if north and east:
		return "rim_ne"
	if north and west:
		return "rim_nw"
	if north:
		return "rim_n"
	if west:
		return "rim_w"
	if east:
		return "rim_e"
	if _lower(cell, Vector2i(1, -1)):
		return "rim_inner_ne"
	if _lower(cell, Vector2i(-1, -1)):
		return "rim_inner_nw"
	return ""


## Schattenstreifen auf dem tieferen Boden direkt unter jeder Wand.
func _add_shadows() -> void:
	var feet: Dictionary[Vector2i, String] = {}
	for cell: Vector2i in _faces:
		var face := _faces[cell]
		var below := cell + Vector2i.DOWN
		if face["stair"] or face["row"] != face["n"] - 1 or not _inside(below) or _tiles.has(below):
			continue
		feet[below] = face["material"]
	for cell: Vector2i in feet:
		var left := not feet.has(cell + Vector2i.LEFT)
		var right := not feet.has(cell + Vector2i.RIGHT)
		var end := "solo" if left and right else ("left" if left else ("right" if right else "middle"))
		_tiles[cell] = [feet[cell], "shadow_" + end]


# --- In die Szene schreiben --------------------------------------------------

func _cliff_layer(root: Node) -> TileMapLayer:
	var layer := root.get_node_or_null("Cliffs") as TileMapLayer
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = "Cliffs"
		# Zwischen Boden (-10) und See (-8): Figuren in Objects stehen immer
		# davor, das passt, weil Wände nur nach Süden zeigen.
		layer.z_index = -9
		layer.tile_set = load(CLIFF_TILESET)
		root.add_child(layer)
		root.move_child(layer, root.get_node("Ground").get_index() + 1)
		layer.owner = root
	return layer


func _water_layer(root: Node) -> TileMapLayer:
	var layer := root.get_node_or_null("Water") as TileMapLayer
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = "Water"
		layer.z_index = -10
		layer.tile_set = load(WATER_TILESET)
		root.add_child(layer)
		root.move_child(layer, root.get_node("Ground").get_index() + 1)
		layer.owner = root
	return layer


## Tiefes Wasser direkt am Land wird zum Ufer (heller, blockiert genauso).
func _paint_water(layer: TileMapLayer) -> void:
	layer.clear()
	var tiles: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(WATER_DIR + "water_layout.json")) as Dictionary)["tiles"]
	for cell: Vector2i in _water:
		var kind := _water[cell]
		if kind == "deep":
			for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
					Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				var other: Vector2i = cell + offset
				if _inside(other) and not _water.has(other):
					kind = "shore"
					break
		var info: Dictionary = tiles[kind]
		layer.set_cell(cell, 0, Vector2i(int(info["col"]), int(info["row"])))


## Tiefere Flächen werden leicht abgedunkelt (je Stufe unter der höchsten
## im Ort mehr): so liest man Höhe auch dort, wo gerade keine Wand im Bild ist.
func _depth_layer(root: Node) -> TileMapLayer:
	var layer := root.get_node_or_null("Depth") as TileMapLayer
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = "Depth"
		# Gleiche Ebene wie der Boden, aber im Baum dahinter: liegt also über
		# dem Boden und unter Wänden, See und Figuren.
		layer.z_index = -10
		layer.tile_set = load(CLIFF_TILESET)
		root.add_child(layer)
		root.move_child(layer, root.get_node("Ground").get_index() + 1)
		layer.owner = root
	return layer


func _paint_depth(layer: TileMapLayer) -> void:
	layer.clear()
	if not _settings.get("depth_shade", true):
		return
	var top := 0
	for column in _height:
		for level in column:
			top = maxi(top, level)
	var tiles: Dictionary = _layout["tiles"]
	for x in _size.x:
		for y in _size.y:
			var steps := mini(top - _height[x][y], 2)
			if steps > 0:
				var info: Dictionary = tiles["depth_%d" % steps]
				layer.set_cell(Vector2i(x, y), 0, Vector2i(int(info["col"]), int(info["row"])))


func _paint_cliffs(layer: TileMapLayer) -> void:
	layer.clear()
	var tiles: Dictionary = _layout["tiles"]
	for cell: Vector2i in _tiles:
		var material: String = _tiles[cell][0]
		var info: Dictionary = tiles[_tiles[cell][1]]
		layer.set_cell(cell, MATERIALS.find(material), Vector2i(int(info["col"]), int(info["row"])))


func _paint_ground(ground: TileMapLayer) -> void:
	var tile_set := ground.tile_set
	var terrains: Dictionary[String, int] = {}
	var colors: Array[Color] = []
	for i in tile_set.get_terrains_count(GROUND_TERRAIN_SET):
		terrains[tile_set.get_terrain_name(GROUND_TERRAIN_SET, i)] = i
		colors.append(tile_set.get_terrain_color(GROUND_TERRAIN_SET, i))
	var default_terrain: int = terrains.get(str(_settings.get("default_ground", "grass")), 0)
	var image := _load_image("ground.png", false)
	var cell_terrain: Array[PackedInt32Array] = []
	for x in _size.x:
		var column := PackedInt32Array()
		column.resize(_size.y)
		for y in _size.y:
			var terrain := default_terrain
			if image and image.get_pixel(x, y).a > 0.5:
				terrain = _nearest_color(colors, image.get_pixel(x, y))
			if _is_stair(Vector2i(x, y)):
				terrain = terrains.get(STAIR_GROUND, terrain)
			column[y] = terrain
		cell_terrain.append(column)

	# Welche Terrains sich an einer Ecke durchsetzen (vorne = stärker). Wege
	# liegen so mit ihren Übergängen auf dem Untergrund, nicht umgekehrt.
	var rank: Dictionary[int, int] = {}
	var priority: Array = _settings.get("ground_priority", DEFAULT_GROUND_PRIORITY)
	for i in priority.size():
		if terrains.has(str(priority[i])):
			rank[terrains[str(priority[i])]] = i
	var tiles := _ground_tiles_by_corners(tile_set)
	ground.clear()
	for x in _size.x:
		for y in _size.y:
			var own := cell_terrain[x][y]
			var corners: Array[int] = []
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				corners.append(_vertex_terrain(cell_terrain, Vector2i(x, y) + offset, rank))
			var options := _ground_options(tiles, corners, own)
			if options.is_empty():
				report.append("kein Boden-Tile für %s bei %s" % [corners, Vector2i(x, y)])
				continue
			# Fester Zufall pro Zelle unter gleichwertigen Varianten.
			var pick: Array = options[absi(hash(Vector2i(x, y))) % options.size()]
			ground.set_cell(Vector2i(x, y), pick[0], pick[1])


## Terrain einer Ecke (Gitterpunkt zwischen bis zu vier Zellen): das stärkste
## der angrenzenden Zellen. Am Kartenrand zählen nur die Zellen innerhalb.
func _vertex_terrain(cell_terrain: Array[PackedInt32Array], vertex: Vector2i, rank: Dictionary[int, int]) -> int:
	var best := -1
	for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var cell: Vector2i = vertex + offset
		if not _inside(cell):
			continue
		var terrain := cell_terrain[cell.x][cell.y]
		if best == -1 or rank.get(terrain, 99) < rank.get(best, 99):
			best = terrain
	return best


## Alle Boden-Kacheln nach ihren vier Ecken: "tl,tr,bl,br" -> [[Quelle, Feld], …].
func _ground_tiles_by_corners(tile_set: TileSet) -> Dictionary[String, Array]:
	var result: Dictionary[String, Array] = {}
	for s in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(s)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var coords := source.get_tile_id(t)
			var data := source.get_tile_data(coords, 0)
			if data.terrain_set != GROUND_TERRAIN_SET:
				continue
			var corners: Array[int] = []
			for corner in CORNERS:
				corners.append(data.get_terrain_peering_bit(corner))
			var key := _corner_key(corners)
			if not result.has(key):
				result[key] = []
			result[key].append([source_id, coords])
	return result


## Passende Kacheln für diese Ecken. Gibt es keine (Übergang zwischen zwei
## Terrains fehlt im TileSet, oder drei Terrains treffen sich), wird
## schrittweise vereinfacht: zuerst bleiben nur das eigene Terrain und das
## häufigste andere, zuletzt nur noch das eigene. An Klippen fällt so eine
## harte Kante gar nicht auf, sie liegt unter der Wand.
func _ground_options(tiles: Dictionary[String, Array], corners: Array[int], own: int) -> Array:
	var exact: Array = tiles.get(_corner_key(corners), [])
	if not exact.is_empty():
		return exact
	var counts: Dictionary[int, int] = {}
	for c in corners:
		if c != own:
			counts[c] = counts.get(c, 0) + 1
	var others := counts.keys()
	others.sort_custom(func(a: int, b: int) -> bool: return counts[a] > counts[b])
	for other in others:
		var reduced: Array[int] = []
		for c in corners:
			reduced.append(c if c == own or c == other else own)
		var found: Array = tiles.get(_corner_key(reduced), [])
		if not found.is_empty():
			return found
	return tiles.get(_corner_key([own, own, own, own]), [])


func _corner_key(corners: Array[int]) -> String:
	return "%d,%d,%d,%d" % [corners[0], corners[1], corners[2], corners[3]]


func _nearest_color(colors: Array[Color], c: Color) -> int:
	var best := 0
	var best_distance := INF
	for i in colors.size():
		var d := absf(colors[i].r - c.r) + absf(colors[i].g - c.g) + absf(colors[i].b - c.b)
		if d < best_distance:
			best = i
			best_distance = d
	return best


func _place_marks(root: Node) -> void:
	var objects := root.get_node("Objects")
	var old := objects.get_node_or_null("Generated")
	if old:
		objects.remove_child(old)
		old.free()
	var generated := Node2D.new()
	generated.name = "Generated"
	generated.y_sort_enabled = true
	objects.add_child(generated)
	generated.owner = root
	var cells := _marks.keys()
	cells.sort()
	for cell: Vector2i in cells:
		if _faces.has(cell) or _water.get(cell, "shallow") != "shallow":
			report.append("%s bei %s liegt auf einer Wand oder im Wasser, wird ignoriert" % [_marks[cell], cell])
			continue
		var options: Array = MARK_SCENES[_marks[cell]]
		# Fester Zufall pro Kachel: gleiche Pläne ergeben gleiche Orte.
		var pick: int = absi(hash(cell)) % options.size()
		var node: Node2D = (load(options[pick]) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		node.name = "%s_%d_%d" % [_marks[cell].capitalize(), cell.x, cell.y]
		# Fußpunkt etwas unter der Kachelmitte, wie bei Hand gesetzter Deko.
		node.position = Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE - 6)
		if "flip" in node and hash(cell * 7) % 2 == 0:
			node.set("flip", true)
		generated.add_child(node)
		node.owner = root
		_placed += 1
