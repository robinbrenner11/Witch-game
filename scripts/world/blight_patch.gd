@tool
class_name BlightPatch
extends Node2D

## Befallener Boden: welke Ranken der Bitterblüte mit Magenta-Knospen, flach
## auf dem Boden. Zeigt, wo befallene Wesen leben.
## (Platzhalter-Zeichnung, bis es Bodengrafiken für den Befall gibt.)

@export var size: Vector2 = Vector2(200, 120):
	set(value):
		size = value
		queue_redraw()
@export var seed_value: int = 1


func _ready() -> void:
	# Flach unter allem, wie Beete und Hexenring.
	z_index = Decor.FLAT_Z


func _draw() -> void:
	BookStyle.draw_blight(self, Rect2(Vector2.ZERO, size), seed_value)
