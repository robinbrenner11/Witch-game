## Uhr oben rechts: normal knochenweiß, ab der Morgenwarnung warm pulsierend,
## am Tag schneller, in der Ewigen Nacht magenta.
extends TestCase


func before_each() -> void:
	DayCycle.reset()


func _colors_over(seconds: float, label: Label) -> Array:
	var seen := []
	var steps := int(seconds * 30)
	for i in steps:
		label._time += 1.0 / 30.0
		var color: Color = label.current_color()
		if not seen.has(color):
			seen.append(color)
	return seen


func test_colors_by_time() -> void:
	var label := Label.new()
	label.set_script(load("res://scripts/ui/clock.gd"))
	DayCycle.minutes = 22 * 60
	check_eq(_colors_over(3.0, label), [label.NORMAL_COLOR], "Nachts ruhig knochenweiß")
	DayCycle.minutes = 5 * 60 + 30
	var dawn := _colors_over(3.0, label)
	check(dawn.has(label.DAWN_COLOR) and dawn.size() == 2, "Ab 5 Uhr warm pulsierend")
	DayCycle.minutes = 7 * 60
	check(_colors_over(3.0, label).has(label.DAWN_COLOR), "Am Tag pulsierend")
	DayCycle.minutes = 23 * 60
	DayCycle.lengthen_night(1.5)
	check_eq(_colors_over(1.0, label), [label.ENDLESS_NIGHT_COLOR], "Ewige Nacht: magenta")
	label.free()
