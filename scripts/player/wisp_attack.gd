class_name WispAttack
extends Node

## Das Irrlicht kämpft mit (Idee vom 09.10., gewünscht 16.10.): Solange es
## leuchtet und die Hexe im Kampfmodus ist, schießt es von selbst einen
## schwachen Funken auf das nächste befallene Wesen in Reichweite. Kostet
## keine Hexenkraft, der Trank ist der Preis. Hängt als Kind am Wisp-Node
## (PotionEffects legt es an).

# Vorläufige Werte, beim Spielen anpassen.
const INTERVAL := 1.2
const RANGE := 150.0
const DAMAGE := 1
const SPEED := 260.0
const KNOCKBACK := 40.0
const COLOR := Color("#BFD7FF")
# Gegner-Trefferzonen sitzen auf Panzerhöhe, nicht am Fußpunkt.
const AIM_OFFSET := Vector2(0, -8)

var _wait := INTERVAL


func _process(delta: float) -> void:
	var wisp := get_parent() as Node2D
	var player := get_tree().get_first_node_in_group("player") as Player
	if not wisp.visible or player == null or not player.combat_mode:
		# Erst nach einer vollen Pause schießen, wenn der Kampf beginnt.
		_wait = INTERVAL
		return
	_wait -= delta
	if _wait > 0.0:
		return
	var target := _nearest_enemy(wisp.global_position)
	if target == null:
		return
	_wait = INTERVAL
	_shoot(wisp.global_position, target.global_position + AIM_OFFSET)


func _nearest_enemy(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := RANGE
	for enemy in get_tree().get_nodes_in_group("blighted"):
		var distance := from.distance_to((enemy as Node2D).global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


func _shoot(from: Vector2, to: Vector2) -> void:
	var level := get_tree().get_first_node_in_group("level") as Level
	if level == null:
		return
	var spark := Spell.new()
	spark.direction = (to - from).normalized()
	spark.speed = SPEED
	spark.max_distance = RANGE + 30.0
	spark.damage = DAMAGE
	spark.radius = 2.0
	spark.knockback = KNOCKBACK
	spark.color = COLOR
	level.objects.add_child(spark)
	spark.global_position = from
	Sfx.play_at("combat/bolt", from)
