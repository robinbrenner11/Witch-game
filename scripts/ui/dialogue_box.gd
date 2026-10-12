class_name DialogueBox
extends Control

## Dialogfenster am unteren Bildrand: Namensschild, Text, wippender
## Weiter-Pfeil, optional ein Portrait. Wer etwas sagen will (NPC, Schild …),
## ruft show_lines() mit Text-Schlüsseln auf. Mit await wartet man, bis die
## Spielerin alles gelesen hat:
##
##     await box.show_lines("NPC_WATCHMAN", ["DLG_…", "DLG_…"])
##
## Wie Truhe und Kessel hält das Fenster das Spiel an, solange es offen ist,
## also steht auch die Uhr. Grafiken in 1×, das Fenster ist auf scale = 2
## gestellt (wie das Brau-Fenster). Aufbau nach dem Mockup in
## docs/art/ui_generator/dialog.py.

signal finished

# Tippgeschwindigkeit: Buchstaben pro Sekunde.
const CHARS_PER_SECOND := 45.0
const NEXT_FRAMES := 4
const NEXT_FPS := 6.0
const NEXT_FRAME_SIZE := 8
# Mit Portrait rückt der Text nach rechts (Mockup: Portrait 56 px breit).
const TEXT_LEFT := 10.0
const TEXT_LEFT_WITH_PORTRAIT := 74.0
const TEXT_RIGHT := 294.0

var _lines: Array[String] = []
var _index := 0
# Wie viele Buchstaben schon zu sehen sind (Kommazahl, weil pro Frame nur
# ein Bruchteil dazukommt).
var _shown := 0.0
var _time := 0.0

@onready var nameplate: PanelContainer = %Nameplate
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %Text
@onready var next_arrow: TextureRect = %Next
@onready var portrait_frame: Control = %PortraitFrame
@onready var portrait: TextureRect = %Portrait


func _ready() -> void:
	hide()
	# Über die Gruppe finden Schilder und NPCs das Fenster, ohne zu wissen,
	# wo es in der Szene hängt.
	add_to_group("dialogue_box")
	# Eigenes Bild, damit der Pfeil animieren kann, ohne die Datei zu ändern.
	next_arrow.texture = next_arrow.texture.duplicate()


func is_open() -> bool:
	return visible


## Zeigt die Zeilen nacheinander. speaker_key leer = ohne Namensschild.
## Kehrt erst zurück, wenn das Fenster wieder zu ist.
func show_lines(speaker_key: String, lines: Array[String], portrait_texture: Texture2D = null) -> void:
	if lines.is_empty() or visible:
		return
	_lines = lines.duplicate()
	_index = 0
	nameplate.visible = speaker_key != ""
	name_label.text = tr(speaker_key)
	portrait.texture = portrait_texture
	portrait_frame.visible = portrait_texture != null
	var left := TEXT_LEFT_WITH_PORTRAIT if portrait_texture else TEXT_LEFT
	text_label.position.x = left
	text_label.size.x = TEXT_RIGHT - left
	nameplate.position.x = left - 2.0
	_show_line()
	show()
	get_tree().paused = true
	Sfx.play("ui/open")
	await finished


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var frame := int(_time * NEXT_FPS) % NEXT_FRAMES
	(next_arrow.texture as AtlasTexture).region.position.x = frame * NEXT_FRAME_SIZE
	if _is_typing():
		_shown += delta * CHARS_PER_SECOND
		text_label.visible_characters = int(_shown)
		if not _is_typing():
			_finish_line()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


## Klicks landen hier, weil das Fenster den ganzen Bildschirm abdeckt
## (mouse_filter Stop). So klickt man nicht versehentlich durch auf die Welt.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


## Tippt die Zeile noch, wird sie sofort ganz gezeigt. Sonst kommt die nächste.
func _advance() -> void:
	if _is_typing():
		_finish_line()
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		Sfx.play("ui/click")
		_show_line()


func _show_line() -> void:
	text_label.text = tr(_lines[_index])
	_shown = 0.0
	text_label.visible_characters = 0
	next_arrow.hide()


func _finish_line() -> void:
	text_label.visible_characters = -1
	next_arrow.show()


func _is_typing() -> bool:
	return text_label.visible_characters >= 0 \
		and text_label.visible_characters < text_label.get_total_character_count()


func _close() -> void:
	hide()
	get_tree().paused = false
	Sfx.play("ui/close")
	finished.emit()
