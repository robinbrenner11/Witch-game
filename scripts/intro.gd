extends Control

## Einleitung beim neuen Spiel: ein paar Zeilen auf schwarzem Grund, die
## nacheinander einblenden. Eine Taste oder ein Klick zeigt sofort alles, die
## nächste startet das Spiel.

const GAME_SCENE := "res://scenes/main.tscn"
# Schlüssel in data/translations/texts.csv. Spieltexte: keine Gedankenstriche,
# keine typografischen Anführungszeichen, keine Auslassungspunkte.
const LINES: Array[String] = ["INTRO_LINE_1", "INTRO_LINE_2", "INTRO_LINE_3", "INTRO_LINE_4"]
const FADE_TIME := 1.4
# Die Szene ist 2× vergrößert (320 Pixel breit). Längere Zeilen brechen um,
# statt über den Rand hinauszulaufen. Wie breit jede Zeile wirklich wird,
# rechnet _balanced_width aus, damit kein einzelnes Wort allein in der
# letzten Zeile steht – in jeder Sprache, ohne Handarbeit pro Text.
const MAX_LINE_WIDTH := 290.0
const PAUSE_TIME := 0.8
# Umgebrochene Zeilen eines Satzes rücken enger zusammen als die Sätze
# untereinander (Abstand der Sätze: separation von Lines in der Szene), so
# erkennt man, was zusammengehört.
const LINE_SPACING := -1

var _tween: Tween
var _finished := false

@onready var lines_box: VBoxContainer = %Lines
@onready var hint: Label = %Hint


func _ready() -> void:
	for text in LINES:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_constant_override("line_spacing", LINE_SPACING)
		label.modulate.a = 0.0
		lines_box.add_child(label)
		label.custom_minimum_size.x = _balanced_width(label, tr(text))
	hint.modulate.a = 0.0
	# Die letzte Zeile in Gold: Ab hier beginnt die Geschichte der Spielerin.
	lines_box.get_child(LINES.size() - 1).add_theme_color_override("font_color", Color("#D9A441"))
	_tween = create_tween()
	for label in lines_box.get_children():
		_tween.tween_property(label, "modulate:a", 1.0, FADE_TIME)
		_tween.tween_interval(PAUSE_TIME)
	_tween.tween_property(hint, "modulate:a", 1.0, FADE_TIME)
	_tween.tween_callback(func() -> void: _finished = true)


## Schmalste Breite, bei der der Text nicht mehr Zeilen braucht als bei
## voller Breite. So werden die Zeilen eines Satzes etwa gleich lang.
func _balanced_width(label: Label, text: String) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := func(width: float) -> int:
		var height := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
		return roundi(height / font.get_height(font_size))
	var target: int = lines.call(MAX_LINE_WIDTH)
	if target <= 1:
		return minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, MAX_LINE_WIDTH)
	var low := MAX_LINE_WIDTH / target
	var high := MAX_LINE_WIDTH
	while high - low > 2.0:
		var middle := (low + high) / 2.0
		if lines.call(middle) > target:
			low = middle
		else:
			high = middle
	return ceilf(high)


func _unhandled_input(event: InputEvent) -> void:
	var pressed := (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo()
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _finished:
		get_tree().change_scene_to_file(GAME_SCENE)
		return
	# Erster Tastendruck: alles sofort zeigen.
	_tween.kill()
	for label in lines_box.get_children():
		label.modulate.a = 1.0
	hint.modulate.a = 1.0
	_finished = true
