class_name DreamView
extends CanvasLayer

## Zeigt einen Traum beim Schlafen: auf Tiefschwarz eine schmale Mondsichel
## und darunter Bild für Bild der Text, der sich langsam einblendet. E, Leertaste
## oder ein Klick blättert weiter. Liegt über der Schwarzblende.
## (Platzhalter, bis es Traumbilder gibt.)
##
## Benutzung: await DreamView.play(get_tree(), dream)

const BACKGROUND := Color("#0E0A14")
const TEXT_COLOR := Color("#EADFCB")
const MOON := Color("#C6B8BE")
const FADE := 0.8
const TEXT_WIDTH := 420.0
const FONT := preload("res://assets/ui/fonts/game_font.tres")
const FONT_SIZE := 16

signal _next

var _label: Label
var _ready_for_input := false


static func play(tree: SceneTree, dream: DreamData) -> void:
	var view := DreamView.new()
	tree.root.add_child(view)
	await view._show(dream)
	view.queue_free()


func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var moon := Crescent.new()
	moon.position = Vector2(320, 110)
	add_child(moon)
	_label = Label.new()
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	# Außerhalb der UI gilt das Theme nicht, deshalb die Spielschrift direkt.
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(TEXT_WIDTH, 120)
	_label.position = Vector2((640 - TEXT_WIDTH) / 2.0, 150)
	add_child(_label)


func _show(dream: DreamData) -> void:
	for key in dream.lines:
		_label.text = tr(key)
		_label.modulate.a = 0.0
		await create_tween().tween_property(_label, "modulate:a", 1.0, FADE).finished
		_ready_for_input = true
		await _next
		_ready_for_input = false
		await create_tween().tween_property(_label, "modulate:a", 0.0, FADE * 0.5).finished


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		_next.emit()


## Mondsichel aus Pixeln (zwei versetzte Scheiben).
class Crescent:
	extends Node2D

	func _draw() -> void:
		for y in range(-8, 9):
			for x in range(-8, 9):
				var outer := Vector2(x, y).length() <= 8.0
				var inner := Vector2(x + 4, y - 2).length() <= 7.0
				if outer and not inner:
					draw_rect(Rect2(x, y, 1, 1), MOON)
