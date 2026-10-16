extends CanvasModulate

## Färbt die ganze Welt je nach Uhrzeit ein. CanvasModulate wirkt nur auf die
## Welt, nicht auf die UI (die liegt in einem eigenen CanvasLayer).

# Aus der Licht-Vorschau (docs/ASSETS.md): kühles, dunkles Violett. Die
# Mondphase verschiebt es: Bei Neumond ist die Nacht tiefer, bei Vollmond
# heller und silbriger. So fühlt sich jede Nacht im Zyklus etwas anders an.
const NIGHT_COLOR := Color("#665C8F")
const NEW_MOON_NIGHT := Color("#4E4677")
const FULL_MOON_NIGHT := Color("#7C7FAE")


# Höhlen und andere dunkle Orte (Level.darkness): fast schwarz, nur Lichter
# reißen etwas heraus.
const DARK_PLACE := Color("#14111F")


func _process(_delta: float) -> void:
	var night := NEW_MOON_NIGHT.lerp(FULL_MOON_NIGHT, Moon.brightness())
	color = Color.WHITE.lerp(night, DayCycle.night_factor())
	var level := get_tree().get_first_node_in_group("level") as Level
	if level and level.darkness > 0.0:
		color = color.lerp(DARK_PLACE, level.darkness)
