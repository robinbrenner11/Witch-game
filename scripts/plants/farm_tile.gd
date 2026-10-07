extends Node2D

## Ein Beetfeld. Was darauf wächst, steht im Autoload Garden – das Beet zeigt
## es nur an und leitet die Interaktion der Hexe dorthin weiter.

const PLANT_SCENE := preload("res://scenes/plants/plant.tscn")

# Position in der Beetreihe. Endstücke haben einen abgerundeten Damm, der
# nahtlos in die Erde übergeht. Eine Reihe ist also: LEFT_END, MIDDLE …,
# RIGHT_END. Ergibt sich automatisch aus den Nachbarbeeten links und rechts.
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

var shape: BedShape = BedShape.SINGLE
# Fest gewürfelte Mustervariante, damit ein Mittelstück beim Umbauen der
# Reihe nicht jedes Mal anders aussieht.
var _pattern := randi_range(0, 2)

# Anzeige der Pflanze; null, solange nichts wächst.
var plant: Plant = null
# Unter dieser Zelle kennt Garden dieses Beet.
var cell: Vector2i

# Das Beet-Sprite liegt in der Szene an der Oberkante des Tiles (Position
# y = -16, Offset +16). Für die Y-Sortierung zählt die Position: So wird die
# Hexe über dem Beet gezeichnet, sobald ihre Füße das Tile betreten.
@onready var bed_sprite: Sprite2D = $BedSprite


func _ready() -> void:
	cell = Garden.cell_at(global_position)
	Garden.plant_changed.connect(_on_garden_plant_changed)
	Garden.bed_changed.connect(_on_garden_bed_changed)
	_update_shape()
	# Falls hier schon etwas wächst (Spielstand, Rückkehr in den Garten).
	_sync_plant()


func _on_interactable_interacted(player: Node2D) -> void:
	if _pour_held_item():
		return
	if not Garden.has_plant(cell):
		_plant_seed((player as Player).selected_seed)
	elif Garden.is_ripe(cell):
		_harvest()
	else:
		_describe_growing_plant()


## Gießt das Item in der Hand aus, falls es dafür gedacht ist (Hexenschlamm,
## Wachstumstrank, Mondernte). Die Wirkung steht in den Item-Daten. Wächst
## nichts, bleibt das Item erhalten und E macht das Übliche (z. B. ernten).
func _pour_held_item() -> bool:
	var item := ItemData.from_id(Inventory.selected_item_id())
	if item == null or item.use != ItemData.Use.POUR:
		return false
	if not Garden.grow_area(cell, item.pour_radius, item.pour_stages):
		return false
	Inventory.remove(item.id)
	return true


func _plant_seed(seed_data: PlantData) -> void:
	# Ohne Samen in der Hand oder wenn die Sorte aufgebraucht ist, passiert nichts.
	if seed_data == null or not Inventory.remove(seed_data.seed_item_id):
		Messages.post("Die Erde wartet auf Samen.")
		return
	Garden.plant_seed(cell, seed_data.id)
	Journal.complete_goal("plant")


func _harvest() -> void:
	var data := Garden.plant_data_at(cell)
	# Bei vollem Inventar bleibt die Pflanze einfach stehen statt zu verschwinden.
	if not Inventory.add(data.harvest_item_id):
		Messages.post("Kein Platz mehr in der Tasche.")
		return
	# Ist das Inventar genau jetzt voll geworden, gehen die Samen verloren –
	# die Ernte selbst ist wichtiger.
	if data.seeds_on_harvest > 0:
		Inventory.add(data.seed_item_id, data.seeds_on_harvest)
	Garden.remove_plant(cell)


## Gehemmte Pflanzen verraten nicht, warum. Das soll man selbst herausfinden.
func _describe_growing_plant() -> void:
	if Garden.is_growth_blocked(cell):
		Messages.post("Etwas hält sie zurück.")
		return
	# Bewusst vage: Man ahnt, wie weit sie ist, ohne genaue Nächte zu kennen.
	var data := Garden.plant_data_at(cell)
	if data.ripens_only_at_full_moon and Garden.stage_at(cell) == data.stage_count - 2:
		Messages.post("Sie wartet auf etwas am Himmel.")
		return
	var nights_left := data.stage_count - 1 - Garden.stage_at(cell)
	if Garden.stage_at(cell) == 0:
		Messages.post("Noch schläft sie in der Erde.")
	elif nights_left == 1:
		Messages.post("Bald ist sie so weit.")
	else:
		Messages.post("Sie wächst noch.")


# Kommt ein Nachbarbeet dazu oder fällt weg, ändert sich die eigene Form.
func _on_garden_bed_changed(changed_cell: Vector2i) -> void:
	if changed_cell == cell + Vector2i.LEFT or changed_cell == cell + Vector2i.RIGHT:
		_update_shape()


func _update_shape() -> void:
	var left := Garden.has_bed(cell + Vector2i.LEFT)
	var right := Garden.has_bed(cell + Vector2i.RIGHT)
	if left and right:
		shape = BedShape.MIDDLE
	elif right:
		shape = BedShape.LEFT_END
	elif left:
		shape = BedShape.RIGHT_END
	else:
		shape = BedShape.SINGLE
	if shape == BedShape.MIDDLE:
		# Drei Mustervarianten, damit lange Reihen nicht gestempelt aussehen.
		bed_sprite.frame_coords = Vector2i(_pattern, BED_ROW)
	else:
		bed_sprite.frame_coords = Vector2i(CAP_COLUMNS[shape], BED_CAP_ROW)


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
