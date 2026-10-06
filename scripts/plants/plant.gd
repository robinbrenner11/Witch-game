class_name Plant
extends Node2D

## Eine Pflanze wächst über Nacht um eine Stufe. Ob sie wächst, entscheidet
## sie in can_grow_tonight() selbst – dort docken später Bedingungen wie
## Mondphase oder Nachbarpflanzen an.

# Welche Art hier wächst. Muss gesetzt sein, bevor die Pflanze in den
# Szenenbaum kommt (macht das Beet beim Pflanzen).
@export var data: PlantData

var growth_stage: int = 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)
	# Das Spritesheet enthält alle Stufen nebeneinander; hframes teilt es
	# in gleich breite Bilder, frame wählt eins davon aus.
	sprite.texture = data.stages_texture
	sprite.hframes = data.stage_count
	_update_sprite()


func is_ripe() -> bool:
	return growth_stage >= data.stage_count - 1


func can_grow_tonight() -> bool:
	return not is_ripe()


func _on_day_passed(_day: int) -> void:
	if can_grow_tonight():
		growth_stage += 1
		_update_sprite()


func _update_sprite() -> void:
	sprite.frame = growth_stage
