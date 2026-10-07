extends Node2D

## Ein Beetfeld. Was darauf wächst, steht im Autoload Garden – das Beet zeigt
## es nur an und leitet die Interaktion der Hexe dorthin weiter.

const PLANT_SCENE := preload("res://scenes/plants/plant.tscn")
# Vorerst fest hier. Wenn es mehr Tränke mit Wirkung aufs Beet gibt, gehört
# die Wirkung besser in die Item-Daten (Schritt 4: trinken/ausgießen).
const GROWTH_POTION := "potion_growth"
# Hexenschlamm, der Fehlschlag aus dem Kessel, taugt als Dünger.
const SLUDGE := "potion_sludge"

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

# Anzeige der Pflanze; null, solange nichts wächst.
var plant: Plant = null
# Unter dieser Zelle kennt Garden dieses Beet.
var cell: Vector2i

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
	cell = Garden.cell_at(global_position)
	Garden.plant_changed.connect(_on_garden_plant_changed)
	# Falls hier schon etwas wächst (Spielstand, Rückkehr in den Garten).
	_sync_plant()


func _on_interactable_interacted(player: Node2D) -> void:
	var held := Inventory.selected_item_id()
	# Der Trank wirkt auf 3×3, also auch, wenn dieses Beet selbst leer oder
	# reif ist. Verbraucht wird er nur, wenn irgendwo etwas gewachsen ist.
	if held == GROWTH_POTION:
		if Garden.grow_area(cell, 1):
			Inventory.remove(GROWTH_POTION)
	elif not Garden.has_plant(cell):
		_plant_seed((player as Player).selected_seed)
	elif Garden.is_ripe(cell):
		_harvest()
	elif held == SLUDGE:
		Inventory.remove(SLUDGE)
		Garden.grow(cell)


func _plant_seed(seed_data: PlantData) -> void:
	# Ohne Samen in der Hand oder wenn die Sorte aufgebraucht ist, passiert nichts.
	if seed_data == null or not Inventory.remove(seed_data.seed_item_id()):
		print("Keine Samen in der Hand (Hotbar: 1–8 oder Mausrad)")
		return
	Garden.plant_seed(cell, seed_data.id)


func _harvest() -> void:
	var data := Garden.plant_data_at(cell)
	# Bei vollem Inventar bleibt die Pflanze einfach stehen statt zu verschwinden.
	if not Inventory.add(data.crop_item_id()):
		print("Inventar voll")
		return
	# Ist das Inventar genau jetzt voll geworden, gehen die Samen verloren –
	# die Ernte selbst ist wichtiger.
	if data.seeds_on_harvest > 0:
		Inventory.add(data.seed_item_id(), data.seeds_on_harvest)
	print("Geerntet: %s (jetzt %d)" % [data.display_name, Inventory.count(data.crop_item_id())])
	Garden.remove_plant(cell)


func _on_garden_plant_changed(changed_cell: Vector2i) -> void:
	if changed_cell == cell:
		_sync_plant()
	# Jede Änderung im Garten kann eine Aura an- oder ausschalten (Nachtschatten
	# gepflanzt, gewachsen, geerntet). Bei ein paar Dutzend Beeten ist es
	# einfacher, immer nachzusehen, als genau auszurechnen, wen es betrifft.
	elif plant:
		plant.wilted = Garden.is_growth_blocked(cell)


## Bringt die angezeigte Pflanze auf den Stand von Garden: anlegen, Stufe
## setzen oder entfernen.
func _sync_plant() -> void:
	var data := Garden.plant_data_at(cell)
	if data == null:
		if plant:
			# queue_free löscht erst am Ende des Frames – sicherer als sofort,
			# falls in diesem Frame noch jemand auf die Pflanze zugreift.
			plant.queue_free()
			plant = null
		return
	if plant == null or plant.data != data:
		if plant:
			plant.queue_free()
		plant = PLANT_SCENE.instantiate()
		plant.data = data
		# Ursprung der Pflanze ist ihr Wurzelpunkt, knapp unter der Beetmitte.
		# So sortiert die Y-Sortierung sie richtig vor oder hinter die Hexe.
		plant.position = Vector2(0, 5)
		add_child(plant)
	plant.growth_stage = Garden.stage_at(cell)
	plant.wilted = Garden.is_growth_blocked(cell)
