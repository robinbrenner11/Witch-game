extends CanvasModulate

## Färbt die ganze Welt je nach Uhrzeit ein. CanvasModulate wirkt nur auf die
## Welt, nicht auf die UI (die liegt in einem eigenen CanvasLayer).

# Aus der Licht-Vorschau (docs/ASSETS.md): kühles, dunkles Violett.
const NIGHT_COLOR := Color("#665C8F")


func _process(_delta: float) -> void:
	color = Color.WHITE.lerp(NIGHT_COLOR, DayCycle.night_factor())
