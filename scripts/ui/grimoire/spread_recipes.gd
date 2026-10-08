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
const MIN_SLOTS := 18

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


static func state_of(recipe: RecipeData) -> RecipeSlot.State:
	if Grimoire.knows_recipe(recipe):
		return RecipeSlot.State.KNOWN
	if not Grimoire.hinted_ingredients(recipe.result_item_id).is_empty():
		return RecipeSlot.State.HINTED
	return RecipeSlot.State.UNKNOWN


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
		if state_of(recipe) != RecipeSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe)):
			return true
	return false


func build(left: Control, right: Control) -> void:
	var recipes := sorted_recipes()
	if selected == null:
		selected = _first_interesting(recipes)
	_build_index(left, recipes)
	_build_detail(right, selected)
	if selected and state_of(selected) != RecipeSlot.State.UNKNOWN:
		Grimoire.mark_seen(seen_key(selected))


## Am liebsten etwas Neues, sonst das erste bekannte Rezept.
func _first_interesting(recipes: Array[RecipeData]) -> RecipeData:
	for recipe in recipes:
		if state_of(recipe) != RecipeSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe)):
			return recipe
	for recipe in recipes:
		if state_of(recipe) == RecipeSlot.State.KNOWN:
			return recipe
	return recipes[0] if not recipes.is_empty() else null


# --- Linke Seite: Raster -------------------------------------------------------

func _build_index(page: Control, recipes: Array[RecipeData]) -> void:
	var known := recipes.filter(func(r: RecipeData) -> bool: return state_of(r) == RecipeSlot.State.KNOWN).size()
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

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	for f in FILTERS:
		var button := BookStyle.text_button("BOOK_FILTER_" + f.to_upper(),
				BookStyle.INK if f == filter else BookStyle.INK_FAINT)
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
		var slot := RecipeSlot.new()
		if i < recipes.size():
			var recipe := recipes[i]
			slot.recipe = recipe
			slot.state = state_of(recipe)
			slot.selected = recipe == selected
			slot.ready_to_brew = slot.state == RecipeSlot.State.KNOWN and is_ready(recipe)
			slot.is_new = slot.state != RecipeSlot.State.UNKNOWN and not Grimoire.is_seen(seen_key(recipe))
			if filter != "all" and category_of(recipe) != filter:
				slot.modulate.a = 0.3
			slot.chosen.connect(func(s: RecipeSlot) -> void:
				selected = s.recipe
				book.refresh())
		grid.add_child(slot)
	page.add_child(grid)


# --- Rechte Seite: Detail ------------------------------------------------------

func _build_detail(page: Control, recipe: RecipeData) -> void:
	if recipe == null:
		return
	var state := state_of(recipe)
	var potion := ItemData.from_id(recipe.result_item_id)
	if state != RecipeSlot.State.KNOWN:
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

	if not missing.is_empty():
		var link := BookStyle.text_button(tr("BOOK_MISSING") % Inventory.display_name_for(missing[0]) + " >", BookStyle.MISSING)
		link.pressed.connect(func() -> void: book.go_to("herbarium"))
		page.add_child(link)

	var result := HBoxContainer.new()
	result.add_child(BookStyle.label("=", BookStyle.INK))
	result.add_child(BookStyle.icon(potion.icon))
	var kind := "BOOK_KIND_DRINK" if category_of(recipe) == "drink" else "BOOK_KIND_POUR"
	result.add_child(BookStyle.label(kind, BookStyle.INK_FAINT))
	page.add_child(result)
	page.add_child(BookStyle.label(potion.description, BookStyle.INK, text_width))

	var count := Brewing.brew_count(recipe.result_item_id)
	if count > 0:
		page.add_child(BookStyle.label(tr("BOOK_BREWED") % count, BookStyle.INK_FAINT))
	if recipe.margin_note_key != "":
		page.add_child(BookStyle.label(recipe.margin_note_key, BookStyle.INK_VESPERA, text_width))
	if book.opened_from_cauldron:
		var brew := BookStyle.text_button("BOOK_BREW_THIS", BookStyle.GOLD_DARK if is_ready(recipe) else BookStyle.INK_FAINT)
		brew.disabled = not is_ready(recipe)
		brew.pressed.connect(func() -> void: book.brew_this(recipe))
		page.add_child(brew)


## Eine Zutat mit Bestand, z. B. "Mandrake 2/1". Fehlendes in Rot.
## Klick führt zum Herbarium, wo man erfährt, wo sie wächst.
func _ingredient_row(item_id: String, have: int, need: int) -> Control:
	var row := HBoxContainer.new()
	row.add_child(BookStyle.icon(Inventory.icon_for(item_id)))
	var name := BookStyle.text_button(Inventory.display_name_for(item_id), BookStyle.INK)
	name.pressed.connect(func() -> void: book.go_to("herbarium"))
	row.add_child(name)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(BookStyle.label("%d/%d" % [have, need], BookStyle.INK if have >= need else BookStyle.MISSING))
	row.custom_minimum_size.x = text_width
	return row


func _build_unknown(page: Control, recipe: RecipeData, state: RecipeSlot.State) -> void:
	page.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
	var hinted := Grimoire.hinted_ingredients(recipe.result_item_id)
	var row := HBoxContainer.new()
	for item_id in recipe.ingredients:
		if hinted.has(item_id):
			row.add_child(BookStyle.icon(Inventory.icon_for(item_id)))
		else:
			row.add_child(BookStyle.icon(RecipeSlot.UNKNOWN_ICON))
	page.add_child(row)
	page.add_child(BookStyle.label("BOOK_UNDISCOVERED", BookStyle.INK_FAINT, text_width))
	if state == RecipeSlot.State.HINTED:
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
