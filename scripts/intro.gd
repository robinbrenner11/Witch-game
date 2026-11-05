extends Control

## Einleitung beim neuen Spiel: ein paar Zeilen auf schwarzem Grund, die
## nacheinander einblenden. Eine Taste oder ein Klick zeigt sofort alles, die
## nächste fragt nach dem Namen der Hexe. Bestätigen startet das Spiel.

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
# Eingabefeld für den Namen, sobald danach gefragt wird (sonst null).
var _name_field: LineEdit

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
	if _name_field:
		# Tippen landet im Eingabefeld; nur ein Klick daneben holt den Fokus zurück.
		_name_field.grab_focus()
		return
	if _finished:
		ask_name()
		return
	# Erster Tastendruck: alles sofort zeigen.
	_tween.kill()
	for label in lines_box.get_children():
		label.modulate.a = 1.0
	hint.modulate.a = 1.0
	_finished = true


## Nach den Zeilen: Wie heißt die Hexe? Der Name steht später im Grimoire.
## Leer bestätigen geht auch, dann bleibt sie namenlos.
func ask_name() -> void:
	if _name_field:
		return
	# Die Geschichte ist gelesen; ohne sie bleibt Platz für Frage und Feld.
	for label in lines_box.get_children():
		label.hide()
	var prompt := Label.new()
	prompt.text = "INTRO_NAME_PROMPT"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", Color("#D9A441"))
	lines_box.add_child(prompt)
	_name_field = LineEdit.new()
	_name_field.max_length = Grimoire.NAME_MAX_LENGTH
	_name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_field.custom_minimum_size = Vector2(120, 0)
	_name_field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_name_field.context_menu_enabled = false
	_name_field.text_submitted.connect(_on_name_submitted)
	# Eigene Gestalt statt Godots grauem Standardfeld: dunkler Grund, Goldrand,
	# eckig wie die übrigen Rahmen im Spiel.
	for state in ["normal", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#0E0A14")
		box.border_color = Color("#D9A441") if state == "focus" else Color("#6E1830")
		box.set_border_width_all(1)
		box.set_content_margin_all(3)
		_name_field.add_theme_stylebox_override(state, box)
	_name_field.add_theme_color_override("font_color", Color("#EADFCB"))
	_name_field.add_theme_color_override("caret_color", Color("#D9A441"))
	lines_box.add_child(_name_field)
	hint.text = tr("INTRO_NAME_HINT") % InputHints.key_for("ui_accept")
	_name_field.grab_focus()


## Speichert den Namen (ohne Szenenwechsel, damit Tests es prüfen können).
func store_name(text: String) -> void:
	Grimoire.witch_name = Grimoire.clean_name(text)


func _on_name_submitted(text: String) -> void:
	store_name(text)
	get_tree().change_scene_to_file(GAME_SCENE)
