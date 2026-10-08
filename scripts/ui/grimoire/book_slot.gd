class_name BookSlot
extends Control

## Ein Platz in einem Raster des Grimoire (Rezepte, Herbarium, Digitalis,
## People). Feste Plätze, auch leere bleiben sichtbar (gepunktet).
## Zustände: unbekannt (?), angedeutet (Silhouette mit ~), bekannt (Bild).
## Ein goldenes Quadrat markiert etwas Besonderes, bei Rezepten "alle
## Zutaten sind da". Neues glimmt magenta, bis es angesehen wurde.

signal chosen(slot: BookSlot)

enum State { EMPTY, UNKNOWN, HINTED, KNOWN }

const UNKNOWN_ICON := preload("res://assets/ui/brew_unknown.png")

# Was der Platz zeigt (RecipeData, EntryData …); das Raster weiß, was es ist.
var data: Variant
# Das Bild des Eintrags. Der Platz hält die Textur selbst fest: draw_texture
# merkt sich nur einen Verweis für die Grafikkarte, und würde die Datei mit
# dem Bild freigegeben, erschiene ein weißes Quadrat.
var icon: Texture2D
var state := State.EMPTY
var selected := false
var marked := false
var is_new := false

var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * BookStyle.SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP if state != State.EMPTY else Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if is_new:
		_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(self)
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if state == State.EMPTY:
		BookStyle.draw_dotted_rect(self, rect, BookStyle.INK_FAINT)
		return
	draw_rect(rect, BookStyle.SHEET_SHADOW)
	BookStyle.draw_frame(self, rect, BookStyle.GOLD if selected else BookStyle.INK_FAINT)
	if selected:
		BookStyle.draw_frame(self, rect.grow(-1), BookStyle.GOLD_DARK)
	var icon_pos := (size - Vector2(16, 16)) / 2.0
	match state:
		State.UNKNOWN:
			draw_texture(UNKNOWN_ICON, icon_pos)
		State.HINTED:
			# Silhouette: das Bild, ganz in Tinte getaucht.
			if icon:
				draw_texture(icon, icon_pos, Color(BookStyle.AUBERGINE, 0.7))
			draw_string(get_theme_default_font(), Vector2(size.x - 7, 9), "~", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BookStyle.MAGENTA)
		State.KNOWN:
			if icon:
				draw_texture(icon, icon_pos)
	if marked:
		draw_rect(Rect2(size.x - 5, 2, 3, 3), BookStyle.GOLD)
	if is_new:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		BookStyle.draw_frame(self, rect, Color(BookStyle.MAGENTA, 0.3 + 0.7 * pulse))
