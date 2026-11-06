class_name NightJournal
extends CanvasLayer

## Die Bilanz der vergangenen Nacht beim Einschlafen: eine Buchseite über der
## Schwarzblende. Inhalt liefert NightLog; weiter geht es mit einer Taste.
## Bewusst nichts über das, was über Tag wächst (das entdeckt man im Garten).

const THEME := preload("res://assets/ui/menu_theme.tres")
const WIDTH := 300.0
const FADE_TIME := 0.35
# So lange nimmt die Seite keine Taste an, damit man sie nicht aus Versehen
# wegdrückt, weil man gerade noch E am Bett gedrückt hat.
const MIN_SHOW_TIME := 0.5
const CONTINUE_ACTIONS: Array[StringName] = [&"interact", &"ui_accept", &"ui_cancel"]

signal closed

var _panel: PanelContainer
var _ready_for_input := false


func _ready() -> void:
	# Über der Schwarzblende (ScreenFade liegt auf 100).
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("night_journal")


## Zeigt die Seite und wartet, bis sie weggedrückt wurde.
func show_lines(title: String, lines: Array[String]) -> void:
	_build(title, lines)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, FADE_TIME)
	await get_tree().create_timer(MIN_SHOW_TIME).timeout
	_ready_for_input = true
	await closed
	var out := create_tween()
	out.tween_property(_panel, "modulate:a", 0.0, FADE_TIME)
	await out.finished
	_panel.get_parent().queue_free()
	_panel = null


func is_showing() -> bool:
	return _panel != null


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input or _panel == null:
		return
	for action in CONTINUE_ACTIONS:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_ready_for_input = false
			closed.emit()
			return


func _build(title: String, lines: Array[String]) -> void:
	var root := Control.new()
	root.theme = THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BookStyle.BONE
	style.border_color = BookStyle.GOLD_DARK
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	style.shadow_color = BookStyle.AUBERGINE
	style.shadow_size = 0
	style.shadow_offset = Vector2(3, 3)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	box.add_child(BookStyle.heading(title, BookStyle.INK_PLAYER, WIDTH))
	for line in lines:
		box.add_child(BookStyle.label(line, BookStyle.INK, WIDTH))
	var hint := BookStyle.label(tr("NIGHTLOG_CONTINUE") % InputHints.key_for("interact"), BookStyle.INK_FAINT, WIDTH)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(hint)
