class_name Plant
extends Node2D

## Zeigt eine Pflanze im Beet an. Ihr Zustand (Art, Stufe) liegt im Autoload
## Garden – das Beet setzt data und growth_stage von dort aus. Ob und wann sie
## wächst, entscheidet Garden.

# Welche Art hier wächst. Muss gesetzt sein, bevor die Pflanze in den
# Szenenbaum kommt (macht das Beet).
@export var data: PlantData

# Ein Setter: läuft bei jeder Zuweisung, so passt das Bild immer zur Stufe.
var growth_stage: int = 0:
	set(value):
		growth_stage = value
		if is_node_ready():
			_update_sprite()

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: NightLight = $Glow


func _ready() -> void:
	# Das Spritesheet enthält alle Stufen nebeneinander; hframes teilt es
	# in gleich breite Bilder, frame wählt eins davon aus.
	sprite.texture = data.stages_texture
	sprite.hframes = data.stage_count
	glow.texture = data.glow_texture
	glow.color = data.glow_color
	glow.base_energy = data.glow_energy
	glow.position = data.glow_offset
	_update_sprite()


func is_ripe() -> bool:
	return growth_stage >= data.stage_count - 1


func _update_sprite() -> void:
	sprite.frame = growth_stage
	# Erst reife Pflanzen leuchten – so wird das Reifwerden nachts sichtbar.
	glow.enabled = is_ripe() and data.glow_texture != null
