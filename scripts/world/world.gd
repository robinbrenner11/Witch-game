extends Node2D

# @onready holt die Nodes erst, wenn die Szene fertig geladen ist –
# vorher existieren die Kinder noch nicht.
@onready var ground: TextureRect = $Ground
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	# Die Kamera soll nie über den Kartenrand hinaus zeigen. Die Grenzen
	# werden aus der Bodenfläche gelesen statt fest eingetragen, damit sie
	# automatisch mitwachsen, wenn die Karte größer wird.
	# (Die Wände unter "Bounds" müssen dann noch von Hand verschoben werden.)
	var bounds := ground.get_rect()
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
