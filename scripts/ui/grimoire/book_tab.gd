class_name BookTab
extends Control

## Ein Lesezeichen-Band am rechten Buchrand. Vorerst eine farbige Fläche je
## Kapitel (Icons später). Gesperrte Kapitel sind von der Bitterblüte
## überwuchert, Kapitel mit Neuem glimmen magenta.

signal chosen(chapter: ChapterData)

var chapter: ChapterData
var active := false:
	set(value):
		active = value
		_update_size()
var locked := false
var has_new := false

var _time := 0.0


func _init(for_chapter: ChapterData) -> void:
	chapter = for_chapter
	tooltip_text = chapter.title_key
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_size()


func _process(delta: float) -> void:
	if has_new:
		_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(chapter)
		accept_event()


func _update_size() -> void:
	size = Vector2(BookStyle.TAB_WIDTH_ACTIVE if active else BookStyle.TAB_WIDTH, BookStyle.TAB_HEIGHT)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BookStyle.BLACK)
	var inner := rect.grow_individual(0, -1, -1, -1)
	draw_rect(inner, chapter.tab_color.darkened(0.25) if not active else chapter.tab_color)
	# Lichtkante oben (Licht von oben links).
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), chapter.tab_color.lightened(0.25))
	if locked:
		draw_rect(inner, BookStyle.WILT_DARK)
		BookStyle.draw_blight(self, inner, chapter.order)
	elif has_new:
		# Pulsierendes Glimmen, wie bei den losen Seiten in der Welt.
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		BookStyle.draw_frame(self, inner, Color(BookStyle.MAGENTA, 0.4 + 0.6 * pulse))
