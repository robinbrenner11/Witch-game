extends Node

## Zählt die Spieltage. Läuft als Autoload, damit jede Szene (Pflanzen, später
## NPCs, Läden …) auf einen neuen Tag reagieren kann, ohne die anderen zu kennen.

signal day_passed(day: int)

var day: int = 1


func advance_day() -> void:
	day += 1
	day_passed.emit(day)


# Nur zum Testen: Später ersetzt Schlafen im Bett diese Taste.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_next_day"):
		advance_day()
		print("Tag %d beginnt" % day)
