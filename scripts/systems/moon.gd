extends Node

## Der Mond: ein Zyklus aus 8 Nächten, vom Neumond bis zum Vollmond, dann
## beginnt er von vorn (docs/design/game_design.md, Abschnitt 5).
##
## Nacht 1 Neumond: Die Bitterblüte ist am stärksten.
## Nacht 2–3 zunehmend, Nacht 4 Halbmond: Halbmondmarkt.
## Nacht 5–7 Dreiviertelmond, Nacht 8 Vollmond: Mondkelch reif, Hexenring aktiv.
##
## Andere Systeme fragen hier nur ab (Moon.is_full(), Moon.phase() …) oder
## hören auf phase_changed. Der Mond hängt allein an der Nacht in DayCycle,
## deshalb muss nichts gespeichert werden.

## Kommt zu Beginn jeder Nacht, auch wenn die Phase gleich bleibt.
signal phase_changed(phase: Phase)

enum Phase { NEW, WAXING, HALF, GIBBOUS, FULL }

const CYCLE_LENGTH := 8
const PHASE_BY_NIGHT: Array[Phase] = [
	Phase.NEW, Phase.WAXING, Phase.WAXING, Phase.HALF,
	Phase.GIBBOUS, Phase.GIBBOUS, Phase.GIBBOUS, Phase.FULL,
]
# Schlüssel in data/translations/texts.csv.
const NAME_KEYS := {
	Phase.NEW: "MOON_NEW",
	Phase.WAXING: "MOON_WAXING",
	Phase.HALF: "MOON_HALF",
	Phase.GIBBOUS: "MOON_GIBBOUS",
	Phase.FULL: "MOON_FULL",
}
# Meldung zu Beginn der Nacht, nur für die besonderen Phasen.
const TONIGHT_KEYS := {
	Phase.NEW: "MSG_MOON_NEW_TONIGHT",
	Phase.HALF: "MSG_MOON_HALF_TONIGHT",
	Phase.FULL: "MSG_MOON_FULL_TONIGHT",
}
# Wie viel der Scheibe leuchtet, für die Zeichnung (0 = neu, 0.5 = voll).
const ILLUMINATION: Array[float] = [0.0, 0.07, 0.14, 0.25, 0.32, 0.38, 0.44, 0.5]
# Wie hell das Mondlicht die Nacht macht (0 = Neumond, 1 = Vollmond).
const BRIGHTNESS: Array[float] = [0.0, 0.15, 0.3, 0.45, 0.6, 0.7, 0.8, 1.0]


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)


## Die wievielte Nacht im Zyklus (1 bis 8).
func night_in_cycle() -> int:
	return (DayCycle.day - 1) % CYCLE_LENGTH + 1


func phase() -> Phase:
	return PHASE_BY_NIGHT[night_in_cycle() - 1]


## Zählt die Zyklen, z. B. damit Mondmoos pro Vollmond nur einmal gibt.
func cycle() -> int:
	return (DayCycle.day - 1) / CYCLE_LENGTH


func is_new() -> bool:
	return phase() == Phase.NEW


func is_half() -> bool:
	return phase() == Phase.HALF


func is_full() -> bool:
	return phase() == Phase.FULL


func phase_name(of_phase: Phase = phase()) -> String:
	return tr(NAME_KEYS[of_phase])


## Nächte bis zur nächsten Nacht mit dieser Phase (0 = heute Nacht).
func nights_until(target: Phase) -> int:
	for ahead in CYCLE_LENGTH:
		var night := (night_in_cycle() - 1 + ahead) % CYCLE_LENGTH
		if PHASE_BY_NIGHT[night] == target:
			return ahead
	return -1


func illumination() -> float:
	return ILLUMINATION[night_in_cycle() - 1]


func brightness() -> float:
	return BRIGHTNESS[night_in_cycle() - 1]


func _on_day_passed(_day: int) -> void:
	var current := phase()
	if TONIGHT_KEYS.has(current):
		Messages.post(tr(TONIGHT_KEYS[current]))
	phase_changed.emit(current)
