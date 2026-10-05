class_name Interactable
extends Area2D

## Baustein für alles, womit die Hexe per E interagieren kann (Beet, später
## Truhe, Tür, NPC …). Er meldet die Interaktion nur per Signal – was dann
## passiert, entscheidet die Szene, in der er steckt.

signal interacted(player: Node2D)


func _ready() -> void:
	# Fest im Code statt in jeder Szene, damit man es beim Einbauen nicht
	# vergessen kann: Interactables liegen auf Layer 2 und suchen selbst nichts.
	collision_layer = 2
	collision_mask = 0
	monitoring = false


func interact(player: Node2D) -> void:
	interacted.emit(player)
