extends Node2D

## Eine Pflanze wächst über Nacht um eine Stufe. Ob sie wächst, entscheidet
## sie in can_grow_tonight() selbst – dort docken später Bedingungen wie
## Mondphase oder Nachbarpflanzen an.

# Eine Grafik pro Wachstumsstufe; die letzte ist "erntereif".
# Später kommt das aus einer PlantData-Resource je Pflanzenart.
@export var stage_textures: Array[Texture2D] = []

var growth_stage: int = 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)
	_update_sprite()


func is_ripe() -> bool:
	return growth_stage >= stage_textures.size() - 1


func can_grow_tonight() -> bool:
	return not is_ripe()


func _on_day_passed(_day: int) -> void:
	if can_grow_tonight():
		growth_stage += 1
		_update_sprite()


func _update_sprite() -> void:
	sprite.texture = stage_textures[growth_stage]
