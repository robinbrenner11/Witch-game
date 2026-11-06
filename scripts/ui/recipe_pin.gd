class_name RecipePin
extends HBoxContainer

## Gemerktes Rezept im HUD (rechts oben unter Uhr und Mond): Trank, dann jede
## Zutat mit Bestand in der Tasche, fehlende rot. Ist alles da, leuchtet der
## Trank golden. Gemerkt wird auf der Rezeptseite im Grimoire (Brewing.pinned).

const FONT := preload("res://assets/ui/fonts/game_font.tres")
const FONT_SIZE := 24
const ICON_SIZE := 32
const BONE := Color("#EADFCB")
const MISSING := Color("#E0566E")
const GOLD := Color("#D9A441")
const SHADOW := Color(0.054902, 0.0392157, 0.0784314, 0.85)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 6)
	Brewing.changed.connect(refresh)
	Inventory.changed.connect(refresh)
	refresh()


# Buch, Brau- und Truhenfenster blenden die Uhr aus (Gruppe "clock"); der
# Merker richtet sich danach, statt selbst in die Gruppe zu gehen (show()
# würde ihn sonst auch ohne gemerktes Rezept einblenden).
func _process(_delta: float) -> void:
	var clock := get_parent().get_node_or_null("Clock") as CanvasItem
	visible = Brewing.pinned_recipe() != null and (clock == null or clock.visible)


func refresh() -> void:
	for child in get_children():
		child.queue_free()
	var recipe := Brewing.pinned_recipe()
	visible = recipe != null
	if recipe == null:
		return
	var all_there := true
	var parts: Array[Control] = []
	var counted: Array[String] = []
	for item_id in recipe.ingredients:
		if counted.has(item_id):
			continue
		counted.append(item_id)
		var need := recipe.ingredients.count(item_id)
		var have := Inventory.count(item_id)
		all_there = all_there and have >= need
		parts.append(_icon(Inventory.icon_for(item_id)))
		parts.append(_label("%d/%d" % [mini(have, need), need], BONE if have >= need else MISSING))
	var potion := _icon(Inventory.icon_for(recipe.result_item_id))
	potion.modulate = GOLD if all_there else Color.WHITE
	add_child(potion)
	add_child(_label("=", GOLD if all_there else BONE))
	for part in parts:
		add_child(part)


func is_complete() -> bool:
	var recipe := Brewing.pinned_recipe()
	if recipe == null:
		return false
	for item_id in recipe.ingredients:
		if Inventory.count(item_id) < recipe.ingredients.count(item_id):
			return false
	return true


func _icon(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
