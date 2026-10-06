extends Node2D

## Ein Beetfeld. Es weiß nur, ob etwas darauf wächst – wie die Pflanze
## wächst, ist Sache der Pflanze selbst.

const PLANT_SCENE := preload("res://scenes/plants/plant.tscn")

# Position im Beet. Endstücke haben einen abgerundeten Damm, der nahtlos
# in die Erde übergeht. Eine Reihe ist also: LEFT_END, MIDDLE …, RIGHT_END.
enum BedShape { MIDDLE, LEFT_END, RIGHT_END, SINGLE }

# Spalten in ground_atlas.png; die gegossene Version liegt jeweils 3 Spalten
# weiter rechts (für das spätere Gießen).
const BED_ROW := 3
const BED_CAP_ROW := 7
const CAP_COLUMNS := {
	BedShape.LEFT_END: 0,
	BedShape.RIGHT_END: 1,
	BedShape.SINGLE: 2,
}

@export var shape: BedShape = BedShape.MIDDLE
# Platzhalter, bis es ein Inventar gibt: Welche Samen hier per E gepflanzt
# werden, ist fest pro Beet eingestellt.
@export var seed_plant: PlantData

var plant: Plant = null

# Das Beet-Sprite liegt in der Szene an der Oberkante des Tiles (Position
# y = -16, Offset +16). Für die Y-Sortierung zählt die Position: So wird die
# Hexe über dem Beet gezeichnet, sobald ihre Füße das Tile betreten.
@onready var bed_sprite: Sprite2D = $BedSprite


func _ready() -> void:
	if shape == BedShape.MIDDLE:
		# Drei Mustervarianten, damit lange Reihen nicht gestempelt aussehen.
		bed_sprite.frame_coords = Vector2i(randi_range(0, 2), BED_ROW)
	else:
		bed_sprite.frame_coords = Vector2i(CAP_COLUMNS[shape], BED_CAP_ROW)


func _on_interactable_interacted(_player: Node2D) -> void:
	if plant == null:
		_plant_seed()
	elif plant.is_ripe():
		_harvest()


func _plant_seed() -> void:
	if seed_plant == null:
		return
	plant = PLANT_SCENE.instantiate()
	plant.data = seed_plant
	# Ursprung der Pflanze ist ihr Wurzelpunkt, knapp unter der Beetmitte.
	# So sortiert die Y-Sortierung sie richtig vor oder hinter die Hexe.
	plant.position = Vector2(0, 5)
	add_child(plant)


func _harvest() -> void:
	# Platzhalter, bis es ein Inventar gibt.
	print("Geerntet: %s" % plant.data.display_name)
	# queue_free löscht die Pflanze erst am Ende des Frames – sicherer als
	# sofort, falls in diesem Frame noch jemand auf sie zugreift.
	plant.queue_free()
	plant = null
