extends Label

## Uhr oben rechts. Liest einfach jeden Frame die Zeit aus DayCycle – das ist
## billig und spart ein eigenes Signal für jede Spielminute.


func _process(_delta: float) -> void:
	text = "Nacht %d   %02d:%02d" % [DayCycle.day, DayCycle.hour(), DayCycle.minute()]
	if DayCycle.fast_forward:
		text += "  >>"
