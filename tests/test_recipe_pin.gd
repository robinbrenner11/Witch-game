## Rezept merken: Auf der Rezeptseite gemerkt, zeigt das HUD die Zutaten mit
## Bestand. Gespeichert; verschwindet, wenn man genau dieses Rezept ansetzt.
extends TestCase

const MENDING := "potion_mending"


func before_each() -> void:
	SaveGame.new_game()


func _mending() -> RecipeData:
	for recipe in RecipeData.all():
		if recipe.result_item_id == MENDING:
			return recipe
	return null


func test_toggle_and_save() -> void:
	check(Brewing.pinned_recipe() == null, "Anfangs nichts gemerkt")
	Brewing.toggle_pin(MENDING)
	check_eq(Brewing.pinned_recipe(), _mending(), "Heiltrank gemerkt")
	var saved := Brewing.get_save_data()
	Brewing.reset()
	check(Brewing.pinned_recipe() == null, "Neues Spiel: vergessen")
	Brewing.load_save_data(saved)
	check_eq(Brewing.pinned, MENDING, "Nach dem Laden wieder gemerkt")
	Brewing.load_save_data({"pinned": "gibt_es_nicht"})
	check_eq(Brewing.pinned, "", "Unbekanntes Rezept im Spielstand wird verworfen")
	Brewing.toggle_pin(MENDING)
	Brewing.toggle_pin(MENDING)
	check_eq(Brewing.pinned, "", "Zweimal = nicht mehr merken")


func test_unpinned_when_brewing_it() -> void:
	Brewing.toggle_pin(MENDING)
	Brewing.start(["wild_herb", "wild_herb"])
	check_eq(Brewing.pinned, MENDING, "Anderes Gebräu: bleibt gemerkt")
	Brewing.reset()
	Brewing.toggle_pin(MENDING)
	Brewing.start(_mending().ingredients)
	check_eq(Brewing.pinned, "", "Gemerktes Rezept angesetzt: Merker weg")


func test_hud_shows_what_is_missing() -> void:
	var pin := RecipePin.new()
	tree.root.add_child(pin)
	await tree.process_frame
	check(not pin.visible, "Ohne Merker unsichtbar")
	Brewing.toggle_pin(MENDING)
	await tree.process_frame
	check(pin.visible, "Mit Merker sichtbar")
	check(not pin.is_complete(), "Zutaten fehlen")
	for item_id in _mending().ingredients:
		Inventory.add(item_id)
	await tree.process_frame
	check(pin.is_complete(), "Alles in der Tasche")
	pin.queue_free()
	await tree.process_frame
