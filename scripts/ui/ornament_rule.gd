class_name OrnamentRule
extends Control

## Goldene Zierlinie mit Rauten an den Enden und in der Mitte (wie unter der
## Uhr im Zielbild art_src/inspo/). Füllt die Breite des Controls, 5 px hoch.

const GOLD := Color("#D9A441")
const GOLD_LIGHT := Color("#FFB566")


func _init() -> void:
	custom_minimum_size.y = 5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := floorf(size.x)
	draw_rect(Rect2(2, 2, w - 4, 1), GOLD)
	_diamond(Vector2(1, 2), 1)
	_diamond(Vector2(w - 2, 2), 1)
	_diamond(Vector2(floorf(w / 2.0), 2), 2)


## Pixel-Raute um center mit radius Pixeln.
func _diamond(center: Vector2, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		var half := radius - absi(dy)
		draw_rect(Rect2(center.x - half, center.y + dy, half * 2 + 1, 1), GOLD)
	draw_rect(Rect2(center, Vector2.ONE), GOLD_LIGHT)
