class_name BookTab
extends Control

## Ein Lesezeichen am rechten Buchrand: ein farbiges Band und rechts daneben
## der Name des Kapitels. Ein Klick auf Band oder Namen schlägt das Kapitel
## auf. Gesperrte Kapitel sind von der Bitterblüte überwuchert und blass,
## Kapitel mit Neuem glimmen magenta. (Icons auf den Bändern kommen später.)

signal chosen(chapter: ChapterData)

var chapter: ChapterData
var active := false
var locked := false
var has_new := false

var _hovered := false
var _time := 0.0
var _label: Label


func _init(for_chapter: ChapterData) -> void:
	chapter = for_chapter
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = Label.new()
	_label.text = chapter.title_key.replace("CHAPTER_", "TAB_")
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.position = Vector2(BookStyle.TAB_LABEL_X - BookStyle.TAB_X, 0)
	add_child(_label)
	size = Vector2(BookStyle.TAB_LABEL_X - BookStyle.TAB_X + 74, BookStyle.TAB_HEIGHT)
	mouse_entered.connect(func() -> void:
		_hovered = true
		refresh())
	mouse_exited.connect(func() -> void:
		_hovered = false
		refresh())


func refresh() -> void:
	var color := BookStyle.LABEL_LIGHT
	if active or _hovered:
		color = BookStyle.GOLD
	elif locked:
		color = BookStyle.LABEL_DIM
	_label.add_theme_color_override("font_color", color)
	queue_redraw()


func _process(delta: float) -> void:
	if has_new:
		_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(chapter)
		accept_event()


func _draw() -> void:
	var width := BookStyle.TAB_WIDTH_ACTIVE if active or _hovered else BookStyle.TAB_WIDTH
	var rect := Rect2(Vector2.ZERO, Vector2(width, BookStyle.TAB_HEIGHT))
	draw_rect(rect, BookStyle.BLACK)
	var inner := rect.grow_individual(0, -1, -1, -1)
	draw_rect(inner, chapter.tab_color if active else chapter.tab_color.darkened(0.25))
	# Lichtkante oben (Licht von oben links) und ein Schatten unten.
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), chapter.tab_color.lightened(0.3))
	draw_rect(Rect2(inner.position.x, inner.end.y - 1, inner.size.x, 1), chapter.tab_color.darkened(0.5))
	if locked:
		draw_rect(inner, BookStyle.WILT_DARK)
		BookStyle.draw_blight(self, inner, chapter.order)
	elif has_new:
		# Pulsierendes Glimmen am Band und ein Punkt vor dem Namen.
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		BookStyle.draw_frame(self, inner, Color(BookStyle.MAGENTA, 0.4 + 0.6 * pulse))
		draw_rect(Rect2(BookStyle.TAB_LABEL_X - BookStyle.TAB_X - 4, 8, 2, 2), Color(BookStyle.MAGENTA, 0.5 + 0.5 * pulse))
