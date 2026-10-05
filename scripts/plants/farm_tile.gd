extends Node2D

## Ein Beetfeld. Es weiß nur, ob etwas darauf wächst – wie die Pflanze
## wächst, ist Sache der Pflanze selbst.

const PLANT_SCENE := preload("res://scenes/plants/plant.tscn")

var plant: Node2D = null


func _on_interactable_interacted(_player: Node2D) -> void:
	if plant == null:
		plant = PLANT_SCENE.instantiate()
		add_child(plant)
