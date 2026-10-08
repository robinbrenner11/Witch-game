class_name SpreadBlank
extends GrimoireSpread

## Kapitel, deren Inhalt noch nicht gebaut ist (Disziplinen, Herbarium …),
## und versiegelte Kapitel, die die Bitterblüte überwuchert hat.

var sealed := false


func build(left: Control, right: Control) -> void:
	add_title(left)
	if sealed:
		left.add_child(BookStyle.label("BOOK_SEALED", BookStyle.INK_FAINT, text_width))
		for page in [left, right]:
			var vines := Vines.new()
			vines.seed_value = chapter.order + page.get_index()
			page.get_parent().add_child(vines)
			vines.position = page.position
			vines.size = page.size
	else:
		left.add_child(BookStyle.label("BOOK_BLANK", BookStyle.INK_FAINT, text_width))


## Ranken über der ganzen Seite.
class Vines:
	extends Control

	var seed_value := 0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		BookStyle.draw_blight(self, Rect2(Vector2(0, 30), size - Vector2(0, 30)), seed_value)
