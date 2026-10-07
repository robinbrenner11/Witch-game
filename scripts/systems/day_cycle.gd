extends Node

## Spielzeit und Nächte. Läuft als Autoload, damit jede Szene (Pflanzen, Licht,
## später NPCs, Läden …) darauf reagieren kann, ohne die anderen zu kennen.
##
## Die Hexe ist nachtaktiv: Gezählt werden Nächte, und eine neue Nacht beginnt
## um 18:00. Die Pflanzen wachsen tagsüber, während die Hexe ruht – deshalb
## kommt day_passed zur Abenddämmerung.

signal day_passed(day: int)

const MINUTES_PER_DAY := 24 * 60
const NIGHT_START := 18 * 60
# Ab hier ist die Nacht vorbei (siehe DARKNESS_CURVE).
const MORNING := 6 * 60
const START_TIME := 20 * 60
# Normal vergeht pro echter Sekunde eine Spielminute (eine Nacht ≈ 12 Minuten).
const GAME_MINUTES_PER_SECOND := 1.0
# Am Hexenfeuer: eine Spielstunde pro Sekunde.
const FAST_FORWARD_FACTOR := 60.0
# Wie dunkel es zu welcher Uhrzeit ist (Minute, 0 = Tag … 1 = tiefe Nacht).
# Dazwischen wird gleichmäßig übergeblendet: Dämmerung 17:00–19:30,
# Morgengrauen 4:00–6:00.
const DARKNESS_CURVE: Array[Vector2] = [
	Vector2(0, 1.0),
	Vector2(4 * 60, 1.0),
	Vector2(6 * 60, 0.0),
	Vector2(17 * 60, 0.0),
	Vector2(19.5 * 60, 1.0),
	Vector2(24 * 60, 1.0),
]

var day: int = 1
# Minuten seit Mitternacht. float, weil pro Frame nur Bruchteile dazukommen.
var minutes: float = START_TIME
# Zeitraffer, z. B. während die Hexe am Feuer rastet. Endet von selbst, wenn
# die nächste Nacht beginnt, damit man nicht versehentlich durchrauscht.
var fast_forward: bool = false
# Trank "Ewige Nacht": Bis zum Morgen läuft die Zeit um diesen Faktor
# langsamer. 1.5 = die Nacht dauert 50 % länger.
var night_slowdown: float = 1.0


func _process(delta: float) -> void:
	var speed := GAME_MINUTES_PER_SECOND * (FAST_FORWARD_FACTOR if fast_forward else 1.0)
	speed /= night_slowdown
	var before := minutes
	minutes = fmod(minutes + delta * speed, MINUTES_PER_DAY)
	if before < MORNING and minutes >= MORNING:
		night_slowdown = 1.0
	if before < NIGHT_START and minutes >= NIGHT_START:
		fast_forward = false
		advance_day()


## Schlafen im Bett: Der Tag wird übersprungen, es geht direkt mit dem
## Beginn der nächsten Nacht weiter. Egal wann sie schlafen geht, es
## vergeht immer genau ein Tag.
func sleep_until_night() -> void:
	fast_forward = false
	minutes = NIGHT_START
	advance_day()


## Die laufende Nacht dauert länger (bis zum Morgen). Mehrfach trinken
## verlängert nicht weiter.
func lengthen_night(factor: float) -> void:
	night_slowdown = factor


func advance_day() -> void:
	day += 1
	night_slowdown = 1.0
	day_passed.emit(day)


## Neues Spiel: erste Nacht, 20 Uhr.
func reset() -> void:
	day = 1
	minutes = START_TIME
	fast_forward = false
	night_slowdown = 1.0


func get_save_data() -> Dictionary:
	return {"day": day, "minutes": minutes}


func load_save_data(data: Dictionary) -> void:
	day = int(data["day"])
	minutes = float(data["minutes"])
	fast_forward = false


## 0 am Tag, 1 in tiefer Nacht. Licht und Farbstimmung richten sich danach.
func night_factor() -> float:
	for i in range(1, DARKNESS_CURVE.size()):
		var from := DARKNESS_CURVE[i - 1]
		var to := DARKNESS_CURVE[i]
		if minutes <= to.x:
			return lerpf(from.y, to.y, inverse_lerp(from.x, to.x, minutes))
	return 1.0


func hour() -> int:
	return floori(minutes / 60.0)


func minute() -> int:
	return int(minutes) % 60


# Nur zum Testen: Später ersetzt Rasten am Hexenfeuer diese Taste ganz.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_next_day"):
		advance_day()
		print("Nacht %d beginnt" % day)
