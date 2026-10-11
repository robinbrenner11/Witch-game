extends Control

## Übersicht der Steuerung (aus den Einstellungen). Baustein wie das
## Einstellungsmenü: open() zeigt es, beim Schließen kommt das Signal closed.
##
## Die Tasten kommen aus der Tastenbelegung (InputHints), stehen also nie
## doppelt im Text. Zwei Spalten: links der Alltag, rechts alles, was mit
## gezogenem Digitalis anders ist.

signal closed

# Zeilen: [Text-Schlüssel, Taste(n)]. Eine Taste ist ein Aktionsname aus der
# Eingabe-Zuordnung, ein Array mehrerer Aktionen (WASD) oder ein Text-Schlüssel
# in eckigen Klammern für Dinge ohne eigene Aktion (Maustasten im Kampf).
const LEFT_ROWS := [
	["CONTROLS_MOVE", ["move_up", "move_left", "move_down", "move_right"]],
	["CONTROLS_FLOAT", "float"],
	["CONTROLS_INTERACT", "interact"],
	["CONTROLS_USE", "use_item"],
	["CONTROLS_SNAP", "snap"],
	["CONTROLS_HOTBAR", "1-8"],
	["CONTROLS_INVENTORY", "inventory"],
	["CONTROLS_BOOK", "book"],
	["CONTROLS_MENU", "ui_cancel"],
]
const RIGHT_ROWS := [
	["CONTROLS_COMBAT", "combat"],
	["CONTROLS_COMBAT_HEADER", ""],
	["CONTROLS_ATTACK_LIGHT", "attack_light"],
	["CONTROLS_ATTACK_HEAVY", "attack_heavy"],
	["CONTROLS_DASH", "float"],
	["CONTROLS_FORM", "hotbar_next"],
	["CONTROLS_POTION", "potion_quick"],
	["CONTROLS_POTION_NEXT", "potion_next"],
]
const KEY_COLOR := Color("#D9A441")
const DIM_COLOR := Color("#9688A0")
const COLUMN_GAP := 6

@onready var grid: GridContainer = %Grid
@onready var back_button: Button = %BackButton


func _ready() -> void:
	hide()


func open() -> void:
	_build()
	show()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _on_back_button_pressed() -> void:
	_close()


func _close() -> void:
	hide()
	closed.emit()


## Baut die Tabelle bei jedem Öffnen neu: Sprache oder Belegung können sich
## seit dem letzten Mal geändert haben.
func _build() -> void:
	for child in grid.get_children():
		child.queue_free()
	for row in maxi(LEFT_ROWS.size(), RIGHT_ROWS.size()):
		for rows in [LEFT_ROWS, RIGHT_ROWS]:
			if row < rows.size():
				_add_row(rows[row][0], rows[row][1])
			else:
				_add_label("", KEY_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
				_add_label("", DIM_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
			# Eine leere Spalte als Abstand zwischen linker und rechter Hälfte.
			if rows == LEFT_ROWS:
				var gap := Control.new()
				gap.custom_minimum_size.x = COLUMN_GAP
				grid.add_child(gap)


func _add_row(text_key: String, keys: Variant) -> void:
	var key_text := _key_text(keys)
	# Zeile ohne Taste ist eine Zwischenüberschrift (gedämpft).
	_add_label(key_text, KEY_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(tr(text_key), DIM_COLOR if key_text == "" else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)


func _add_label(text: String, color: Color, align: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	# Texte sind schon übersetzt, Godot soll sie nicht noch einmal als Schlüssel lesen.
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	grid.add_child(label)


func _key_text(keys: Variant) -> String:
	if keys is Array:
		var parts: PackedStringArray = []
		for action: String in keys:
			parts.append(InputHints.key_for(action))
		# WASD statt "W A S D": spart Platz und liest sich wie gewohnt.
		return "".join(parts)
	var text := String(keys)
	if text.begins_with("[") and text.ends_with("]"):
		return tr(text.substr(1, text.length() - 2))
	if InputMap.has_action(text):
		return InputHints.key_for(text)
	return text
