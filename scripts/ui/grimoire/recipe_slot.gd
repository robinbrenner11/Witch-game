class_name RecipeSlot
extends Control

## Ein Platz im Rezept-Raster. Feste Plätze, auch leere bleiben sichtbar
## (gepunktet). Zustände: unbekannt (?), angedeutet (Silhouette mit ~),
## bekannt (Trank). Ein goldenes Quadrat heißt: alle Zutaten sind da.

signal chosen(slot: RecipeSlot)

enum State { EMPTY, UNKNOWN, HINTED, KNOWN }

const UNKNOWN_ICON := preload("res://assets/ui/brew_unknown.png")

var recipe: RecipeData
var state := State.EMPTY
var selected := false
var ready_to_brew := false
var is_new := false

var _time := 0.0
# Das Feld hält seine Textur selbst fest. draw_texture merkt sich nur einen
# Verweis für die Grafikkarte; würde die Item-Datei mitsamt Icon freigegeben,
# erschiene statt des Tranks ein weißes Quadrat.
var _icon: Texture2D


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
			# Silhouette: der Trank, ganz in Tinte getaucht.
			draw_texture(_potion_icon(), icon_pos, Color(BookStyle.AUBERGINE, 0.7))
			draw_string(get_theme_default_font(), Vector2(size.x - 7, 9), "~", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BookStyle.MAGENTA)
		State.KNOWN:
			draw_texture(_potion_icon(), icon_pos)
	if ready_to_brew:
		draw_rect(Rect2(size.x - 5, 2, 3, 3), BookStyle.GOLD)
	if is_new:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		BookStyle.draw_frame(self, rect, Color(BookStyle.MAGENTA, 0.3 + 0.7 * pulse))


func _potion_icon() -> Texture2D:
	if _icon == null:
		_icon = Inventory.icon_for(recipe.result_item_id)
	return _icon
