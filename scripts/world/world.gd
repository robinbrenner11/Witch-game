extends Node2D

# @onready holt die Nodes erst, wenn die Szene fertig geladen ist –
# vorher existieren die Kinder noch nicht.
@onready var ground: TileMapLayer = $Ground
@onready var camera: Camera2D = $Objects/Player/Camera2D


func _ready() -> void:
	# Die Kamera soll nie über den Kartenrand hinaus zeigen. Die Grenzen
	# werden aus den bemalten Tiles gelesen statt fest eingetragen, damit sie
	# automatisch mitwachsen, wenn die Karte größer wird.
	# (Die Wände unter "Bounds" müssen dann noch von Hand verschoben werden.)
	# get_used_rect() zählt in Tiles, die Kamera braucht Pixel.
	var tile_size := ground.tile_set.tile_size
	var used := ground.get_used_rect()
	camera.limit_left = used.position.x * tile_size.x
	camera.limit_top = used.position.y * tile_size.y
	camera.limit_right = used.end.x * tile_size.x
	camera.limit_bottom = used.end.y * tile_size.y
