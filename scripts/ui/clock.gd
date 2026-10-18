extends Label

## Uhr oben rechts, darunter eine goldene Zierlinie und die Mondphase
## (Aufbau wie im Zielbild art_src/inspo/). Liest einfach jeden Frame die Zeit
## aus DayCycle – das ist billig und spart ein eigenes Signal für jede Spielminute.

# Knochenweiß normal, Magenta (Magie), solange die Ewige Nacht wirkt.
const NORMAL_COLOR := Color("#EADFCB")
const ENDLESS_NIGHT_COLOR := Color("#E458B1")

@onready var moon_name: Label = %MoonName
@onready var rule: Control = %Rule


func _ready() -> void:
	# Über die Gruppe kann z. B. das Grimoire die Uhr ausblenden.
	add_to_group("clock")


func _process(_delta: float) -> void:
	text = tr("CLOCK_NIGHT") % DayCycle.day + "  ·  %02d:%02d" % [DayCycle.hour(), DayCycle.minute()]
	if DayCycle.fast_forward:
		text += "  >>"
	add_theme_color_override("font_color", ENDLESS_NIGHT_COLOR if DayCycle.night_slowdown > 1.0 else NORMAL_COLOR)
	moon_name.text = Moon.phase_name()
	# Die Zierlinie ist so breit wie die Zeile darüber.
	var width := get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x
	rule.offset_left = -roundf(width) - 2
