extends Control

## Einleitung beim neuen Spiel: ein paar Zeilen auf schwarzem Grund, die
## nacheinander einblenden. Eine Taste oder ein Klick zeigt sofort alles, die
## nächste startet das Spiel.

const GAME_SCENE := "res://scenes/main.tscn"
# Spieltexte: keine Gedankenstriche, keine deutschen Anführungszeichen,
# keine Auslassungspunkte.
const LINES: Array[String] = [
	"Ten years ago, the Bitterbloom woke in the deep woods.",
	"The villagers keep it at bay. Barely.",
	"The old witch they now call Mother Blight fled and never returned.",
	"Her garden has been waiting ever since.",
]
const FADE_TIME := 1.4
const PAUSE_TIME := 0.8

var _tween: Tween
var _finished := false

@onready var lines_box: VBoxContainer = %Lines
@onready var hint: Label = %Hint


func _ready() -> void:
	for text in LINES:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.0
		lines_box.add_child(label)
	hint.modulate.a = 0.0
	# Die letzte Zeile in Gold: Ab hier beginnt die Geschichte der Spielerin.
	lines_box.get_child(LINES.size() - 1).add_theme_color_override("font_color", Color("#D9A441"))
	_tween = create_tween()
	for label in lines_box.get_children():
		_tween.tween_property(label, "modulate:a", 1.0, FADE_TIME)
		_tween.tween_interval(PAUSE_TIME)
	_tween.tween_property(hint, "modulate:a", 1.0, FADE_TIME)
	_tween.tween_callback(func() -> void: _finished = true)


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
