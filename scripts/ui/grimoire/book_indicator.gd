class_name BookIndicator
extends Control

## Kleines Buch oben links im HUD, sobald die Hexe das Grimoire hat. Wartet
## darin etwas Neues (ein Geschenk, eine Pfadwahl, ein neuer Eintrag), glimmt
## es magenta. Ein Klick öffnet das Buch, sonst Taste B.
## (Platzhalter-Zeichnung, bis es ein Icon gibt.)

# Wie oft nachgeschaut wird, ob es Neues gibt. Jeden Frame wäre unnötig.
const CHECK_INTERVAL := 0.5

var book: GrimoireBook

var _has_news := false
var _time := 0.0
var _since_check := CHECK_INTERVAL


func _ready() -> void:
	add_to_group("clock")
	position = Vector2(6, 6)
	size = Vector2(30, 16)
	tooltip_text = "BOOK_INDICATOR"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var key := Label.new()
	key.text = "B"
	key.position = Vector2(18, -1)
	key.add_theme_color_override("font_color", BookStyle.LABEL_DIM)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(key)


func _process(delta: float) -> void:
	modulate.a = 1.0 if Grimoire.has_book and not book.visible else 0.0
	_since_check += delta
	if _since_check >= CHECK_INTERVAL and Grimoire.has_book:
		_since_check = 0.0
		_has_news = book.any_news()
	if _has_news:
		_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and Grimoire.has_book and not get_tree().paused:
		book.open()
		accept_event()


func _draw() -> void:
	if not Grimoire.has_book:
		return
	# Ein kleines Buch: Bordeaux-Einband, Goldecke, Seitenkanten.
	var cover := Rect2(1, 1, 13, 14)
	if _has_news:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_rect(cover.grow(1), Color(BookStyle.MAGENTA, 0.3 + 0.7 * pulse))
	draw_rect(cover, BookStyle.BLACK)
	draw_rect(cover.grow(-1), BookStyle.BORDEAUX)
	draw_rect(Rect2(3, 2, 1, 12), Color("#962C48"))
	draw_rect(Rect2(12, 3, 2, 10), BookStyle.BONE)
	draw_rect(Rect2(12, 3, 1, 10), BookStyle.SHEET_SHADOW)
	draw_rect(Rect2(10, 2, 2, 2), BookStyle.GOLD)
	draw_rect(Rect2(6, 6, 3, 3), BookStyle.GOLD_DARK)
	if _has_news:
		draw_rect(Rect2(13, 0, 3, 3), BookStyle.MAGENTA)
