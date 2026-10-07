extends Node2D

## Alle Beete des Gartens. Welche Zellen Beete sind, steht in Garden
## (Autoload), damit selbst angelegte Beete gespeichert werden; dieser Node
## erzeugt und entfernt die passenden FarmTile-Nodes.
##
## Die Beete, die in der Szene von Hand gesetzt sind, sind die Startbeete:
## Beim allerersten Laden übernimmt Garden sie. Danach zählt nur noch Garden.

const FARM_TILE := preload("res://scenes/plants/farm_tile.tscn")

var _tiles: Dictionary[Vector2i, Node2D] = {}


func _ready() -> void:
	if not Garden.beds_initialized:
		for tile in get_children():
			Garden.add_bed(Garden.cell_at(tile.global_position))
		Garden.beds_initialized = true
	for tile in get_children():
		var cell := Garden.cell_at(tile.global_position)
		if Garden.has_bed(cell) and not _tiles.has(cell):
			_tiles[cell] = tile
		else:
			# Startbeet, das die Hexe inzwischen entfernt hat.
			tile.queue_free()
	for cell in Garden.bed_cells():
		if not _tiles.has(cell):
			_spawn(cell)
	Garden.bed_changed.connect(_on_bed_changed)


func _on_bed_changed(cell: Vector2i) -> void:
	if Garden.has_bed(cell) and not _tiles.has(cell):
		_spawn(cell)
	elif not Garden.has_bed(cell) and _tiles.has(cell):
		_tiles[cell].queue_free()
		_tiles.erase(cell)


func _spawn(cell: Vector2i) -> void:
	var tile: Node2D = FARM_TILE.instantiate()
	# Beete stehen mit ihrem Ursprung in der Tile-Mitte.
	tile.global_position = Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0
	add_child(tile)
	_tiles[cell] = tile
