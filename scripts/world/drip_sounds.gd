class_name DripSounds
extends Node2D

## Einzelne Tropfen in unregelmäßigen Abständen, solange die Hexe in Hörweite
## ist. Am Höhlenspalt hinter dem Wasserfall (S2): Man hört die Höhle, bevor
## man hineinkann. Sfx wählt die Variante (world/cave_drip_1..3) selbst.

@export var sound_id: String = "world/cave_drip"
## Ab dieser Entfernung (Pixel) tropft es hörbar.
@export var hearing_distance: float = 260.0
@export var min_wait: float = 1.2
@export var max_wait: float = 3.5

var _wait := 0.0


func _ready() -> void:
	_wait = randf_range(min_wait, max_wait)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = randf_range(min_wait, max_wait)
	if player_in_range():
		# Leicht versetzt, damit es nicht immer aus demselben Punkt kommt.
		Sfx.play_at(sound_id, global_position + Vector2(randf_range(-12, 12), randf_range(-6, 6)))


func player_in_range() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player != null and player.global_position.distance_to(global_position) <= hearing_distance
