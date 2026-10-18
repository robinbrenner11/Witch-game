extends CanvasModulate

## Färbt die ganze Welt je nach Uhrzeit ein. CanvasModulate wirkt nur auf die
## Welt, nicht auf die UI (die liegt in einem eigenen CanvasLayer).

# Kühles Nachtblau, das die Farben stehen lässt (Grün bleibt grün, Rot bleibt
# rot), statt alles grau-violett zu machen. Die Dunkelheit kommt aus dem
# Kontrast zu den warmen Lichtinseln, nicht aus dem Abdunkeln (Zielbild
# art_src/inspo/, 18.10.2026). Die Mondphase verschiebt es: Bei Neumond ist
# die Nacht tiefer, bei Vollmond heller und silbriger.
const NEW_MOON_NIGHT := Color("#6A78B8")
const FULL_MOON_NIGHT := Color("#8C9AD0")


# Höhlen und andere dunkle Orte (Level.darkness): fast schwarz, nur Lichter
# reißen etwas heraus.
const DARK_PLACE := Color("#14111F")


func _process(_delta: float) -> void:
	var night := NEW_MOON_NIGHT.lerp(FULL_MOON_NIGHT, Moon.brightness())
	color = Color.WHITE.lerp(night, DayCycle.night_factor())
	var level := get_tree().get_first_node_in_group("level") as Level
	if level and level.darkness > 0.0:
		color = color.lerp(DARK_PLACE, level.darkness)
