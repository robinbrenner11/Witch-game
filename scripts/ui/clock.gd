extends Label

## Uhr oben rechts, darunter die Mondphase. Liest einfach jeden Frame die Zeit
## aus DayCycle – das ist billig und spart ein eigenes Signal für jede Spielminute.

# Knochenweiß normal, Magenta (Magie), solange die Ewige Nacht wirkt.
const NORMAL_COLOR := Color("#EADFCB")
const ENDLESS_NIGHT_COLOR := Color("#E458B1")

@onready var moon_name: Label = %MoonName


func _process(_delta: float) -> void:
	text = "Nacht %d   %02d:%02d" % [DayCycle.day, DayCycle.hour(), DayCycle.minute()]
	if DayCycle.fast_forward:
		text += "  >>"
	add_theme_color_override("font_color", ENDLESS_NIGHT_COLOR if DayCycle.night_slowdown > 1.0 else NORMAL_COLOR)
	moon_name.text = DayCycle.moon_phase_name()
