extends Label

## Uhr oben rechts, darunter die Mondphase. Liest einfach jeden Frame die Zeit
## aus DayCycle – das ist billig und spart ein eigenes Signal für jede Spielminute.

# Knochenweiß normal, Magenta (Magie), solange die Ewige Nacht wirkt.
const NORMAL_COLOR := Color("#EADFCB")
const ENDLESS_NIGHT_COLOR := Color("#E458B1")
# Ab der Morgenwarnung wird die Uhr warm wie die aufgehende Sonne und
# pulsiert: erst langsam, am Tag (die Sonne brennt draußen) schneller.
# So sieht man die Gefahr auch, wenn man die Meldung um 5 Uhr verpasst hat.
const DAWN_COLOR := Color("#FFB566")
# Sekunden pro Pulsschlag.
const DAWN_PULSE := 1.6
const DAY_PULSE := 0.6

var _time := 0.0

@onready var moon_name: Label = %MoonName


func _ready() -> void:
	# Über die Gruppe kann z. B. das Grimoire die Uhr ausblenden.
	add_to_group("clock")


func _process(delta: float) -> void:
	_time += delta
	text = tr("CLOCK_NIGHT") % DayCycle.day + "   %02d:%02d" % [DayCycle.hour(), DayCycle.minute()]
	if DayCycle.fast_forward:
		text += "  >>"
	add_theme_color_override("font_color", current_color())
	moon_name.text = Moon.phase_name()


## Farbe der Uhr je nach Lage: Ewige Nacht, Morgen naht, Tag oder normal.
## Das Pulsieren springt zwischen zwei Stufen statt weich zu blenden.
func current_color() -> Color:
	if DayCycle.night_slowdown > 1.0:
		return ENDLESS_NIGHT_COLOR
	var pulse := 0.0
	if DayCycle.is_daytime():
		pulse = DAY_PULSE
	elif DayCycle.minutes >= DayCycle.DAWN_WARNING and DayCycle.minutes < DayCycle.MORNING:
		pulse = DAWN_PULSE
	if pulse == 0.0:
		return NORMAL_COLOR
	return DAWN_COLOR if sin(_time * TAU / pulse) >= 0.0 else NORMAL_COLOR.lerp(DAWN_COLOR, 0.5)
