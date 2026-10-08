class_name SpreadRecipes
extends GrimoireSpread

## Kapitel Recipes: links das Raster aller Rezepte mit Filtern, rechts das
## gewählte Rezept groß. Unbekannte Rezepte zeigen so viele ? wie Zutaten,
## angedeutete (Gerücht) die bekannten Zutaten. Klick auf eine Zutat springt
## ins Herbarium. Am Kessel gibt es "Brew this".
## Design: docs/design/grimoire.md, Abschnitt 1 (Recipes).

const FILTERS: Array[String] = ["all", "pour", "drink", "throw", "gift"]
const COLUMNS := 6
# So viele Plätze zeigt das Raster mindestens; leere bleiben gepunktet
# sichtbar und verraten, dass es noch mehr zu entdecken gibt.
const MIN_SLOTS := 12

var filter := "all"
var selected: RecipeData


static func sorted_recipes() -> Array[RecipeData]:
	var recipes := RecipeData.all().duplicate()
	# Zweier-Rezepte zuerst, dann die stärkeren Dreier-Rezepte.
	recipes.sort_custom(func(a: RecipeData, b: RecipeData) -> bool:
		if a.ingredients.size() != b.ingredients.size():
			return a.ingredients.size() < b.ingredients.size()
		return a.result_item_id < b.result_item_id)
	return recipes


static func seen_key(recipe: RecipeData) -> String:
	return "recipe/" + recipe.result_item_id


static func state_of(recipe: RecipeData) -> BookSlot.State:
	if Grimoire.knows_recipe(recipe):
		return BookSlot.State.KNOWN
	if not Grimoire.hinted_ingredients(recipe.result_item_id).is_empty():
		return BookSlot.State.HINTED
	return BookSlot.State.UNKNOWN


## Wofür der Trank ist; bestimmt den Filter. Werfen und Geschenk kommen mit
## den Wurf- und NPC-Tränken.
static func category_of(recipe: RecipeData) -> String:
	var item := ItemData.from_id(recipe.result_item_id)
	if item and item.use == ItemData.Use.DRINK:
		return "drink"
	return "pour"


## Liegen alle Zutaten im Inventar? (Später auch die Truhe.)
static func is_ready(recipe: RecipeData) -> bool:
	for item_id in recipe.ingredients:
		if Inventory.count(item_id) < recipe.ingredients.count(item_id):
			return false
	return true


func has_new() -> bool:
	for recipe in sorted_recipes():
		if state_of(recipe) != BookSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe)):
			return true
	return false


func build(left: Control, right: Control) -> void:
	var recipes := sorted_recipes()
	if selected == null:
		selected = _first_interesting(recipes)
	_build_index(left, recipes)
	_build_detail(right, selected)
	if selected and state_of(selected) != BookSlot.State.UNKNOWN:
		Grimoire.mark_seen(seen_key(selected))


## Am liebsten etwas Neues, sonst das erste bekannte Rezept.
func _first_interesting(recipes: Array[RecipeData]) -> RecipeData:
	for recipe in recipes:
		if state_of(recipe) != BookSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe)):
			return recipe
	for recipe in recipes:
		if state_of(recipe) == BookSlot.State.KNOWN:
			return recipe
	return recipes[0] if not recipes.is_empty() else null


# --- Linke Seite: Raster -------------------------------------------------------

func _build_index(page: Control, recipes: Array[RecipeData]) -> void:
	var known := recipes.filter(func(r: RecipeData) -> bool: return state_of(r) == BookSlot.State.KNOWN).size()
	var header := HBoxContainer.new()
	header.add_child(BookStyle.label(chapter.title_key, BookStyle.INK_VESPERA_TITLE))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(BookStyle.label("%d/%d" % [known, recipes.size()], BookStyle.INK_FAINT))
	var moon := CompletionMoon.new()
	moon.fraction = float(known) / maxf(recipes.size(), 1)
	header.add_child(moon)
	page.add_child(header)
	page.add_child(BookStyle.rule(text_width))

	# Filter: der gewählte unterstrichen; ohne passende Rezepte blass.
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 4)
	for f in FILTERS:
		var count := recipes.filter(func(r: RecipeData) -> bool: return f == "all" or category_of(r) == f).size()
		var color := BookStyle.INK if f == filter else (BookStyle.INK_FAINT if count == 0 else BookStyle.GOLD_DARK)
		var button := BookStyle.text_button("BOOK_FILTER_" + f.to_upper(), color)
		button.disabled = count == 0
		if f == filter:
			button.add_child(Underline.new())
		button.pressed.connect(func() -> void:
			filter = f
			book.refresh())
		filters.add_child(button)
	page.add_child(filters)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for i in maxi(MIN_SLOTS, ceili(recipes.size() / float(COLUMNS)) * COLUMNS):
		var slot := BookSlot.new()
		if i < recipes.size():
			var recipe := recipes[i]
			slot.data = recipe
			slot.icon = Inventory.icon_for(recipe.result_item_id)
			slot.state = state_of(recipe)
			slot.selected = recipe == selected
			# Goldenes Quadrat: alle Zutaten liegen bereit ("ready to brew").
			slot.marked = slot.state == BookSlot.State.KNOWN and is_ready(recipe)
			slot.is_new = slot.state != BookSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe))
			if filter != "all" and category_of(recipe) != filter:
				slot.modulate.a = 0.3
			slot.chosen.connect(func(s: BookSlot) -> void:
				selected = s.data
				book.refresh())
		grid.add_child(slot)
	page.add_child(grid)


# --- Rechte Seite: Detail ------------------------------------------------------

func _build_detail(page: Control, recipe: RecipeData) -> void:
	if recipe == null:
		return
	var state := state_of(recipe)
	var potion := ItemData.from_id(recipe.result_item_id)
	if state != BookSlot.State.KNOWN:
		_build_unknown(page, recipe, state)
		return
	# Selbst erbraut steht es in der Tinte der Spielerin, gelesen in Vesperas.
	var ink := BookStyle.INK_PLAYER if Grimoire.learned_by_experiment(recipe) else BookStyle.INK_VESPERA_TITLE
	page.add_child(BookStyle.heading(potion.display_name, ink, text_width))

	var missing: Array[String] = []
	var counted: Array[String] = []
	for item_id in recipe.ingredients:
		if counted.has(item_id):
			continue
		counted.append(item_id)
		var need := recipe.ingredients.count(item_id)
		var have := Inventory.count(item_id)
		if have < need:
			missing.append(item_id)
		page.add_child(_ingredient_row(item_id, have, need))

	page.add_child(BookStyle.rule_plain(text_width))
	var result := HBoxContainer.new()
	result.add_child(BookStyle.label("=", BookStyle.INK))
	result.add_child(BookStyle.icon(potion.icon))
	var kind := "BOOK_USE_DRINK_SHORT" if category_of(recipe) == "drink" else "BOOK_USE_POUR_SHORT"
	result.add_child(BookStyle.label(kind, BookStyle.INK))
	var count := Brewing.brew_count(recipe.result_item_id)
	if count > 0:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		result.add_child(spacer)
		result.add_child(BookStyle.label(tr("BOOK_BREWED") % count, BookStyle.INK_FAINT))
	result.custom_minimum_size.x = text_width
	page.add_child(result)
	page.add_child(BookStyle.label(potion.description, BookStyle.INK, text_width))
	if recipe.margin_note_key != "":
		page.add_child(BookStyle.margin_note(recipe.margin_note_key, text_width))
	if book.opened_from_cauldron:
		var brew := BookStyle.button("BOOK_BREW_THIS")
		brew.disabled = not missing.is_empty()
		brew.pressed.connect(func() -> void: book.brew_this(recipe))
		page.add_child(brew)


## Eine Zutat: wie viele nötig sind, und rechts ein Häkchen, wenn genug in
## der Tasche ist, sonst "fehlt" in Rot. Ein Klick auf den Namen führt ins
## Herbarium, wo man erfährt, wo sie wächst.
func _ingredient_row(item_id: String, have: int, need: int) -> Control:
	var row := HBoxContainer.new()
	row.add_child(BookStyle.icon(Inventory.icon_for(item_id)))
	row.add_child(BookStyle.label(tr("BOOK_NEED") % need, BookStyle.INK_FAINT))
	var name := BookStyle.text_button(Inventory.display_name_for(item_id), BookStyle.INK)
	name.tooltip_text = "BOOK_TO_HERBARIUM"
	name.pressed.connect(func() -> void: book.show_item_entry(item_id))
	row.add_child(name)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if have >= need:
		row.add_child(SpreadDiscipline.Check.new())
	else:
		row.add_child(BookStyle.label("BOOK_HAVE_MISSING", BookStyle.MISSING))
	row.custom_minimum_size.x = text_width
	return row


func _build_unknown(page: Control, recipe: RecipeData, state: BookSlot.State) -> void:
	page.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
	var hinted := Grimoire.hinted_ingredients(recipe.result_item_id)
	var row := HBoxContainer.new()
	for item_id in recipe.ingredients:
		if hinted.has(item_id):
			row.add_child(BookStyle.icon(Inventory.icon_for(item_id)))
		else:
			row.add_child(BookStyle.icon(BookSlot.UNKNOWN_ICON))
	page.add_child(row)
	page.add_child(BookStyle.label("BOOK_UNDISCOVERED", BookStyle.INK_FAINT, text_width))
	if state == BookSlot.State.HINTED:
		page.add_child(BookStyle.label("BOOK_RUMOR", BookStyle.INK_PLAYER, text_width))


## Vollständigkeit als Mond: Neumond (nichts) bis Vollmond (alles), 8 Stufen.
class CompletionMoon:
	extends Control

	var fraction := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(13, 11)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var stage := floorf(clampf(fraction, 0.0, 1.0) * 7.0) / 7.0
		MoonIcon.draw_moon(self, Vector2(1, 0), stage * 0.5, 5, 1, BookStyle.GOLD, BookStyle.SHEET_SHADOW_DEEP)


## Strich unter dem gewählten Filter.
class Underline:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		offset_top = -2
		offset_bottom = -1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, 1), BookStyle.GOLD_DARK)
