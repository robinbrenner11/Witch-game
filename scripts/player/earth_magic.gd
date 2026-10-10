extends Node2D

## Schnippen (R): Die Hexe weckt die Erde vor sich zu einem Beet oder legt
## ein leeres Beet wieder schlafen. Nur dort, wo der Ort es erlaubt (Garten),
## und nur auf reiner Erde. Eigener Node, damit player.gd klein bleibt; hier
## können später weitere kleine Zauber dazukommen.

const SPARK_COLOR := Color("#E458B1")

@onready var player: Player = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	# Beim Schlafen oder Ortswechsel ist die Steuerung aus.
	if event.is_action_pressed("snap") and player.can_act() and not player.combat_mode:
		_snap()
		get_viewport().set_input_as_handled()


func _snap() -> void:
	player.play_action("snap")
	# Die Erde reagiert erst im Moment des Schnippens (Frame 2 der Animation).
	await player.wait_for_action_frame(1)
	var level := get_tree().get_first_node_in_group("level") as Level
	# Die Zelle direkt vor der Hexe, dort wo auch E wirkt.
	var cell := Garden.cell_at(player.interaction_area.global_position)
	if level == null or not level.allows_bed_at(cell):
		Messages.deny(tr("MSG_EARTH_TOO_DEEP"))
		return
	if Garden.has_plant(cell) or _has_wild_growth(cell):
		Messages.deny(tr("MSG_ALREADY_GROWING"))
		return
	var center := Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0
	if Garden.has_bed(cell):
		Garden.remove_bed(cell)
		Sfx.play_at("garden/bed_sleep", center)
	else:
		Garden.add_bed(cell)
		Grimoire.complete_goal("wake")
		Sfx.play_at("garden/bed_wake", center)
	_burst(level, center)


## Wildgras und Unkraut müssen erst weggeräumt werden (siehe WildGrowth).
func _has_wild_growth(cell: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("wild"):
		if Garden.cell_at(node.global_position) == cell:
			return true
	return false


## Ein kurzer Funkenregen in Magenta über der Zelle, danach löscht er sich selbst.
func _burst(level: Level, at: Vector2) -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.amount = 24
	sparks.lifetime = 0.7
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(12, 8)
	sparks.direction = Vector2.UP
	sparks.spread = 60.0
	sparks.gravity = Vector2(0, 30)
	sparks.initial_velocity_min = 15.0
	sparks.initial_velocity_max = 40.0
	sparks.color = SPARK_COLOR
	# Leuchtet auch nachts, unabhängig vom Licht.
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = material
	sparks.z_index = 5
	level.add_child(sparks)
	sparks.global_position = at
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
