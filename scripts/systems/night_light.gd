class_name NightLight
extends PointLight2D

## Ein Licht, das nur nachts leuchtet und mit der Dämmerung sanft angeht.
## Für alles, was im Dunkeln glüht: Pflanzen, Feuer, später Kerzen, Fenster.

@export var base_energy: float = 1.0
# 0 = ruhiges Licht, z. B. 0.1 = leichtes Flackern wie bei Feuer.
@export var flicker: float = 0.0

var _time := randf() * 10.0


func _process(delta: float) -> void:
	_time += delta
	# Zwei überlagerte Sinuswellen wirken unregelmäßiger als eine.
	var wobble := 1.0 + flicker * (sin(_time * 7.0) + sin(_time * 11.3)) * 0.5
	energy = base_energy * wobble * DayCycle.night_factor()
