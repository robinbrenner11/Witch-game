class_name Shimmer
extends CanvasItem

## Lässt ein Bild sanft auf- und abschimmern (Deckkraft über self_modulate,
## damit ein Ein- oder Ausblenden am Eltern-Node unabhängig bleibt).
## Z. B. der geschlossene Mondsteg: nur eine Ahnung auf dem Wasser.

@export var min_alpha: float = 0.08
@export var max_alpha: float = 0.25
## Sekunden für ein volles Auf und Ab.
@export var period: float = 3.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	var wave := (sin(_time / period * TAU) + 1.0) * 0.5
	self_modulate.a = lerpf(min_alpha, max_alpha, wave)
