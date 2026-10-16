class_name DialogueBox
extends Control

## Dialogfenster am unteren Bildrand: Namensschild, Text, wippender
## Weiter-Pfeil, optional ein Portrait. Wer etwas sagen will (NPC, Schild …),
## ruft show_lines() mit Text-Schlüsseln auf. Mit await wartet man, bis die
## Spielerin alles gelesen hat:
##
##     await box.show_lines("NPC_WATCHMAN", ["DLG_…", "DLG_…"])
##
## Antworten zur Auswahl (Tausch, Fragen): choose() zeigt bis zu drei Zeilen
## gleichzeitig, mehr werden mit dem Cursor gerollt. Ergebnis ist der Index
## der Antwort, -1 bei Esc:
##
##     var picked := await box.choose("NPC_MOTHER_MOSS", ["TRADE_…", "TRADE_NOTHING"])
##
## Wie Truhe und Kessel hält das Fenster das Spiel an, solange es offen ist,
## also steht auch die Uhr. Grafiken in 1×, das Fenster ist auf scale = 2
## gestellt (wie das Brau-Fenster). Aufbau nach dem Mockup in
## docs/art/ui_generator/dialog.py.

signal finished
signal chosen(index: int)

# Tippgeschwindigkeit: Buchstaben pro Sekunde.
const CHARS_PER_SECOND := 45.0
const NEXT_FRAMES := 4
const NEXT_FPS := 6.0
const NEXT_FRAME_SIZE := 8
# Mit Portrait rückt der Text nach rechts (Mockup: Portrait 56 px breit).
const TEXT_LEFT := 10.0
const TEXT_LEFT_WITH_PORTRAIT := 74.0
const TEXT_RIGHT := 294.0
# So viele Antworten passen gleichzeitig ins Fenster (wie die 3 Textzeilen).
const CHOICE_ROWS := 3
const CHOICE_BG := preload("res://assets/ui/dialog_choice_bg.png")
const CURSOR := preload("res://assets/ui/dialog_cursor.png")

var _lines: Array[String] = []
var _index := 0
# Wie viele Buchstaben schon zu sehen sind (Kommazahl, weil pro Frame nur
# ein Bruchteil dazukommt).
var _shown := 0.0
var _time := 0.0
# Antwort-Auswahl: Texte, markierte Zeile, erste sichtbare Zeile (Rollen).
var _choices: Array[String] = []
var _choice_index := 0
var _choice_offset := 0
var _choice_labels: Array[Label] = []
var _choice_bg: NinePatchRect
var _cursor: TextureRect

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
	_set_speaker(speaker_key, portrait_texture)
	_show_line()
	show()
	get_tree().paused = true
	Sfx.play("ui/open")
	await finished


## Zeigt Antworten zur Auswahl und wartet. Gibt den Index zurück, -1 bei Esc.
func choose(speaker_key: String, options: Array[String], portrait_texture: Texture2D = null) -> int:
	if options.is_empty() or visible:
		return -1
	_set_speaker(speaker_key, portrait_texture)
	_choices = options.duplicate()
	_choice_index = 0
	_choice_offset = 0
	_build_choice_rows()
	text_label.hide()
	next_arrow.hide()
	_update_choices()
	show()
	get_tree().paused = true
	Sfx.play("ui/open")
	var picked: int = await chosen
	return picked


func is_choosing() -> bool:
	return visible and not _choices.is_empty()


func _set_speaker(speaker_key: String, portrait_texture: Texture2D) -> void:
	nameplate.visible = speaker_key != ""
	name_label.text = tr(speaker_key)
	portrait.texture = portrait_texture
	portrait_frame.visible = portrait_texture != null
	var left := TEXT_LEFT_WITH_PORTRAIT if portrait_texture else TEXT_LEFT
	text_label.position.x = left
	text_label.size.x = TEXT_RIGHT - left
	nameplate.position.x = left - 2.0


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
	if is_choosing():
		_choice_input(event)
		get_viewport().set_input_as_handled()
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
	if is_choosing():
		var mouse := event as InputEventMouse
		var row := _row_at(mouse.position) if mouse else -1
		var click := event as InputEventMouseButton
		if row >= 0 and event is InputEventMouseMotion and row != _choice_index:
			_choice_index = row
			_update_choices()
		elif row >= 0 and click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_pick(row)
		accept_event()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _choice_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_move_choice(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_move_choice(1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_pick(_choice_index)
	elif event.is_action_pressed("ui_cancel"):
		_pick(-1)


func _move_choice(step: int) -> void:
	_choice_index = wrapi(_choice_index + step, 0, _choices.size())
	Sfx.play("ui/hover")
	_update_choices()


## Drei Zeilen in Größe und Schrift der Textzeile, dazu Markierung und Cursor.
## Einmal gebaut, danach nur noch befüllt.
func _build_choice_rows() -> void:
	if not _choice_labels.is_empty():
		return
	var window := text_label.get_parent()
	_choice_bg = NinePatchRect.new()
	_choice_bg.texture = CHOICE_BG
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_choice_bg.set_patch_margin(side, 4)
	_choice_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(_choice_bg)
	for i in CHOICE_ROWS:
		var row := text_label.duplicate(0) as Label
		row.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.visible_characters = -1
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		window.add_child(row)
		_choice_labels.append(row)
	_cursor = TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = CURSOR
	atlas.region = Rect2(0, 0, CURSOR.get_width() / 2.0, CURSOR.get_height())
	_cursor.texture = atlas
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(_cursor)


func _update_choices() -> void:
	# Die markierte Zeile bleibt im sichtbaren Ausschnitt.
	_choice_offset = clampi(_choice_offset, _choice_index - CHOICE_ROWS + 1, _choice_index)
	var line_height := float(text_label.get_line_height())
	for i in CHOICE_ROWS:
		var row := _choice_labels[i]
		var option := _choice_offset + i
		row.visible = option < _choices.size()
		if not row.visible:
			continue
		row.text = tr(_choices[option])
		row.position = Vector2(text_label.position.x + 6.0, text_label.position.y + i * line_height)
		row.size = Vector2(text_label.size.x - 6.0, line_height)
		if option == _choice_index:
			_choice_bg.position = row.position - Vector2(3, 0)
			_choice_bg.size = Vector2(row.size.x + 4.0, line_height)
			_cursor.position = Vector2(row.position.x - 12.0, row.position.y + (line_height - _cursor.texture.get_height()) / 2.0)
	_choice_bg.show()
	_cursor.show()


func _row_at(screen_position: Vector2) -> int:
	for i in CHOICE_ROWS:
		var row := _choice_labels[i]
		if row.visible and row.get_global_rect().has_point(screen_position):
			return _choice_offset + i
	return -1


func _pick(index: int) -> void:
	for row in _choice_labels:
		row.hide()
	_choice_bg.hide()
	_cursor.hide()
	text_label.show()
	_choices.clear()
	hide()
	get_tree().paused = false
	Sfx.play("ui/click" if index >= 0 else "ui/close")
	chosen.emit(index)


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
