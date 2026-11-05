class_name ProgressFeedback
extends Node2D

## Rückmeldung, wenn die Hexe in einer Disziplin aufsteigt: ein kurzes
## Glockenspiel und goldene und magenta Funken, die um sie aufsteigen. Die
## Meldung im Text kommt wie bisher vom Grimoire; das hier macht den Moment
## spürbar. Eigener Node, damit player.gd klein bleibt (wie VitalsFeedback).

const GOLD := Color("#D9A441")
const MAGIC := Color("#E458B1")
# Die Funken steigen etwa ab Brusthöhe auf.
const CHEST := Vector2(0, -22)

var player: Node2D


func _ready() -> void:
	player = get_parent() as Node2D
	Grimoire.level_up.connect(_on_level_up)


func _on_level_up(_discipline_id: String, _level: int) -> void:
	Sfx.play("ui/level_up")
	var level := get_tree().get_first_node_in_group("level") as Level
	if level == null or not is_instance_valid(player):
		return
	var at := player.global_position + CHEST
	_rising_motes(level.objects, at, GOLD, 14)
	_rising_motes(level.objects, at, MAGIC, 8)


## Ruhiger als Kampf-Funken: aus einem Ring um die Hexe, gut eine Sekunde
## lang langsam aufsteigend (negative Schwerkraft), dann aus.
func _rising_motes(parent: Node, at: Vector2, color: Color, amount: int) -> void:
	var motes := CPUParticles2D.new()
	motes.one_shot = true
	motes.explosiveness = 0.7
	motes.amount = amount
	motes.lifetime = 1.1
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 9.0
	motes.direction = Vector2.UP
	motes.spread = 25.0
	motes.gravity = Vector2(0, -25)
	motes.initial_velocity_min = 8.0
	motes.initial_velocity_max = 22.0
	motes.color = color
	motes.material = CombatFx.unshaded()
	motes.z_index = 4
	parent.add_child(motes)
	motes.global_position = at
	motes.emitting = true
	motes.finished.connect(motes.queue_free)
