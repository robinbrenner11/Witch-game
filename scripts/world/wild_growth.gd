class_name WildGrowth
extends Node

## Lässt in einem Ort von selbst etwas wachsen, das man einsammeln kann
## (Wildgras, Unkraut, später Pilze, Beeren …). Der Zustand liegt im Autoload
## Wilds; dieser Node erzeugt nur die passenden Objekte und sucht freie
## Plätze für Neues. Ein Ort kann mehrere davon haben, je einen pro Sorte
## von Dingen mit eigenen Regeln.
##
## Die Objekte (Szenen in kinds) melden mit dem Signal "collected", dass sie
## eingesammelt und weg sind (siehe weed.gd, forage.gd). Haben sie die
## Variablen wild_place und wild_id, bekommen sie die mit, um ihren eigenen
## Zustand in Wilds zu lesen (z. B. Beerenstrauch gepflückt).

# Wie Neues entsteht, siehe Wilds.MODES.
enum Regrow { STEADY, RESPAWN, CHANCE, NONE }

# Unter diesem Namen merkt sich Wilds den Zustand, zusammen mit dem Ort.
@export var group: String = "weeds"
# Daraus wird zufällig gewählt, wenn etwas Neues wächst.
@export var kinds: Array[PackedScene] = []
# Neues wächst in Büscheln, damit man es als Sammelbares erkennt und nicht
# für einzelne Halme im Boden hält. So viele Stück pro Büschel (min, max).
@export var cluster_size: Vector2i = Vector2i(3, 7)
# So viele Büschel liegen beim allerersten Besuch schon da.
@export var start_clusters: int = 3
# Mehr Einzelstücke wachsen nie gleichzeitig.
@export var max_count: int = 24
@export var regrow: Regrow = Regrow.STEADY
# STEADY: So viele Nächte nach dem letzten Einsammeln wächst nichts nach.
@export var pause_nights: int = 1
# RESPAWN: Nach so vielen Nächten kommt ein eingesammeltes Stück woanders wieder.
@export var respawn_nights: int = 3
# CHANCE: Wahrscheinlichkeit pro Nacht für ein neues Stück.
@export_range(0.0, 1.0) var chance: float = 0.25
# Nur auf diesen Böden (Terrain-Nummern im Ground-TileSet: 6 Erde, 7 Waldboden,
# 8 Wiese). Pfad (2) ist absichtlich nicht dabei.
@export var terrains: Array[int] = [6, 7, 8]
# Nur in diesem Bereich (Pixel). Leer = der ganze Ort.
@export var area: Rect2 = Rect2()
# Mindestabstand zu anderen Objekten, damit nichts in Bäumen oder Möbeln steckt.
@export var clearance: float = 24.0
# Abstand der Stücke innerhalb eines Büschels und wie weit es sich ausbreitet.
@export var spacing: float = 11.0
@export var cluster_radius: Vector2 = Vector2(26, 16)

var _place := ""
var _level: Level


func _ready() -> void:
	_level = get_parent() as Level
	_place = "%s/%s" % [_level.scene_file_path.get_file().get_basename(), group]
	var first_visit := not Wilds.is_known(_place)
	Wilds.register(_place, {
		"mode": Wilds.MODES[regrow], "max": max_count, "pause": pause_nights,
		"respawn_nights": respawn_nights, "chance": chance,
	})
	# Warten, bis der Ort fertig aufgebaut ist (Beete, Deko), sonst sind die
	# freien Plätze noch nicht bekannt.
	await get_tree().process_frame
	var items := Wilds.items(_place)
	for id: String in items:
		var item: Dictionary = items[id]
		_spawn(id, load(item["scene"]), Vector2(item["x"], item["y"]))
	var clusters := start_clusters if first_visit else Wilds.take_pending(_place)
	for i in clusters:
		_grow_cluster()


## Ein neues Büschel an einer freien Stelle: meist eine Sorte, ab und zu eine
## andere dazwischen. Nie mehr als max_count Stücke im Ort.
func _grow_cluster() -> void:
	var room := max_count - Wilds.items(_place).size()
	var cells := _free_cells()
	if room <= 0 or cells.is_empty() or kinds.is_empty():
		return
	var cell: Vector2i = cells.pick_random()
	var center := Vector2(cell * Garden.TILE_SIZE) + Vector2(16, 20)
	var size := mini(randi_range(cluster_size.x, cluster_size.y), room)
	var main_kind: PackedScene = kinds.pick_random()
	var taken := _taken_positions()
	var wild := _wild_positions()
	var covers := _cover_rects()
	var placed := 0
	for attempt in size * 8:
		if placed == size:
			break
		# Das erste Stück in die Mitte, die anderen drumherum.
		var offset := Vector2.ZERO
		if placed > 0:
			offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * cluster_radius
		var at := (center + offset).round()
		if not _point_is_free(at, taken, wild) or _is_covered(at, covers):
			continue
		var scene: PackedScene = main_kind if randf() < 0.75 else kinds.pick_random()
		var id := Wilds.add_item(_place, scene.resource_path, at)
		_spawn(id, scene, at)
		wild.append(at)
		placed += 1


func _point_is_free(at: Vector2, taken: Array[Vector2], wild: Array[Vector2]) -> bool:
	var cell := Garden.cell_at(at)
	if area.has_area() and not area.has_point(at):
		return false
	if not _has_allowed_ground(cell) or (_level.allows_beds and Garden.has_bed(cell)):
		return false
	for p in taken:
		if p.distance_to(at) < clearance:
			return false
	for p in wild:
		if p.distance_to(at) < spacing:
			return false
	return true


func _spawn(id: String, scene: PackedScene, at: Vector2) -> void:
	var node: Node2D = scene.instantiate()
	node.position = at
	node.add_to_group("wild")
	if "flip" in node:
		node.flip = randf() < 0.5
	if "wild_id" in node:
		node.wild_place = _place
		node.wild_id = id
	node.collected.connect(func() -> void: Wilds.remove_item(_place, id))
	_level.objects.add_child(node)


## Alle Zellen, in deren Mitte ein neues Büschel anfangen darf.
func _free_cells() -> Array[Vector2i]:
	var taken := _taken_positions()
	taken.append_array(_wild_positions())
	var covers := _cover_rects()
	# Nicht in den Streifen unter der Hotbar, dort kommt man nicht hin.
	var bottom := _level.pixel_rect().end.y - _level.hud_margin_bottom
	var result: Array[Vector2i] = []
	for cell in _level.ground.get_used_cells():
		var center := Vector2(cell * Garden.TILE_SIZE) + Vector2(16, 16)
		if center.y > bottom - 16:
			continue
		if area.has_area() and not area.has_point(center):
			continue
		if not _has_allowed_ground(cell):
			continue
		if _level.allows_beds and Garden.has_bed(cell):
			continue
		if _is_covered(center, covers):
			continue
		var blocked := false
		for p in taken:
			if p.distance_to(center) < clearance:
				blocked = true
				break
		if not blocked:
			result.append(cell)
	return result


func _has_allowed_ground(cell: Vector2i) -> bool:
	var data := _level.ground.get_cell_tile_data(cell)
	if data == null:
		return false
	for corner in [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER]:
		if data.get_terrain_peering_bit(corner) not in terrains:
			return false
	return true


## Wo schon etwas steht: alle eingesetzten Szenen unter Objects (Deko, Kessel,
## Beete, andere Wildpflanzen), Zaunkacheln und die Ankunftspunkte der Ausgänge.
func _taken_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for node in _level.objects.find_children("*", "Node2D", true, false):
		if node.is_in_group("wild"):
			continue
		if node.scene_file_path != "":
			result.append(node.global_position)
		elif node is TileMapLayer:
			for cell in (node as TileMapLayer).get_used_cells():
				result.append(node.to_global(node.map_to_local(cell)))
	for exit in _level.find_children("To*", "Area2D", false, false):
		if exit is Exit:
			result.append(exit.spawn_position())
			result.append(exit.global_position)
	return result


func _wild_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group("wild"):
		result.append((node as Node2D).global_position)
	return result


## Bereiche hinter Baumkronen: Dort würde man Sammelbares nicht sehen.
func _cover_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in _level.objects.find_children("*", "Node2D", true, false):
		if node is Decor and node.fade_when_behind:
			result.append((node as Decor).cover_rect())
	return result


## Liegt at hinter einer Baumkrone?
func _is_covered(at: Vector2, covers: Array[Rect2]) -> bool:
	for rect in covers:
		if rect.has_point(at):
			return true
	return false
