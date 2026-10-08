extends Control

## Das Buch der alten Hexe (Taste B, sobald man es gefunden hat). Seite 1 ist
## ihre Notiz mit den ersten Zielen, die durchgestrichen werden, sobald sie
## erledigt sind. Danach folgt je Rezept eine Seite: Bekannte Rezepte zeigen
## Zutaten, Trank und Beschreibung, unbekannte nur so viele "?" wie Zutaten –
## ein kleiner Hinweis, ohne etwas zu verraten.
##
## Blättern mit den Pfeiltasten oder den Knöpfen, schließen mit B oder Esc.
## Solange das Buch offen ist, ist das Spiel pausiert.

const UNKNOWN := preload("res://assets/ui/brew_unknown.png")
const GOLD := Color("#D9A441")
const INK_DONE := Color("#9688A0")

# Schlüssel in data/translations/texts.csv.
const NOTE_START := "BOOK_NOTE_START"
const GOAL_TEXTS := {
	"plant": "GOAL_PLANT",
	"brew": "GOAL_BREW",
	"sleep": "GOAL_SLEEP",
	"wake": "GOAL_WAKE",
}

var _page := 0
var _recipes: Array[RecipeData] = []

@onready var content: VBoxContainer = %Content
@onready var page_label: Label = %PageLabel


func _ready() -> void:
	hide()
	add_to_group("recipe_book")
	# Zweier-Rezepte zuerst, dann die stärkeren Dreier-Rezepte.
	_recipes = RecipeData.all().duplicate()
	_recipes.sort_custom(func(a: RecipeData, b: RecipeData) -> bool:
		if a.ingredients.size() != b.ingredients.size():
			return a.ingredients.size() < b.ingredients.size()
		return a.result_item_id < b.result_item_id)


func open() -> void:
	if not Grimoire.has_book:
		return
	show()
	get_tree().paused = true
	_show_page()


func close() -> void:
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		# Nur öffnen, wenn kein anderes Fenster offen ist.
		if event.is_action_pressed("book") and not get_tree().paused and Grimoire.has_book:
			open()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("book") or event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("ui_left"):
		_turn(-1)
	elif event.is_action_pressed("ui_right"):
		_turn(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_previous_pressed() -> void:
	_turn(-1)


func _on_next_pressed() -> void:
	_turn(1)


func _turn(direction: int) -> void:
	_page = clampi(_page + direction, 0, _recipes.size())
	_show_page()


func _show_page() -> void:
	for child in content.get_children():
		child.queue_free()
	if _page == 0:
		_build_note()
	else:
		_build_recipe(_recipes[_page - 1])
	page_label.text = "%d / %d" % [_page + 1, _recipes.size() + 1]


func _build_note() -> void:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size.x = 230
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Zusammengesetzter Text, deshalb tr() von Hand: Godot übersetzt nur
	# Texte automatisch, die genau ein Schlüssel sind.
	var bbcode := tr(NOTE_START)
	for goal in Grimoire.GOALS:
		var line := tr(GOAL_TEXTS[goal])
		if Grimoire.is_goal_done(goal):
			line = "[s][color=#%s]%s[/color][/s]" % [INK_DONE.to_html(false), line]
		bbcode += "\n" + line
	text.text = bbcode
	content.add_child(text)


func _build_recipe(recipe: RecipeData) -> void:
	var known := Grimoire.knows_recipe(recipe)
	var potion := ItemData.from_id(recipe.result_item_id)

	var title := Label.new()
	title.text = potion.display_name if known else "???"
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	# Zutaten + Zutaten = Trank, unbekannt als lauter Fragezeichen.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for i in recipe.ingredients.size():
		if i > 0:
			row.add_child(_text("+"))
		row.add_child(_icon(Inventory.icon_for(recipe.ingredients[i]) if known else UNKNOWN))
	row.add_child(_text("="))
	row.add_child(_icon(potion.icon if known else UNKNOWN))
	content.add_child(row)

	var description := _text(potion.description if known else "BOOK_UNDISCOVERED")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 230
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(description)
	if known:
		var use := _text("BOOK_USE_DRINK" if potion.use == ItemData.Use.DRINK else "BOOK_USE_POUR")
		use.add_theme_color_override("font_color", INK_DONE)
		use.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(use)


func _icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return icon


func _text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	return label
