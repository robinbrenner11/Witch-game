extends StaticBody2D

## Der Kessel: Zwei Zutaten hinein, heraus kommt ein Trank – oder Hexenschlamm,
## wenn die Kombination zu keinem Rezept passt. Rezepte verrät das Spiel nicht,
## man findet sie durch Ausprobieren.
##
## E mit einer Zutat in der Hand: Zutat hinein.
## E mit etwas anderem (oder leeren Händen): erste Zutat wieder herausholen.

const FAILED_RESULT := "potion_sludge"
const FRAME_TIME := 0.4

# Im Inspector eingetragen. Neue Rezepte = neue Datei in data/recipes/ und hier
# in die Liste ziehen.
@export var recipes: Array[RecipeData] = []

var _first_ingredient := ""
var _frame_timer := 0.0
var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ingredient_icon: Sprite2D = $IngredientIcon


func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer >= FRAME_TIME:
		_frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes
	# Die eingeworfene Zutat schwebt leicht wippend über dem Sud. round() hält
	# sie auf ganzen Pixeln.
	_time += delta
	ingredient_icon.position.y = -36 + round(sin(_time * 3.0) * 1.5)


func _on_interactable_interacted(_player: Node2D) -> void:
	var held := Inventory.selected_item_id()
	if not _is_ingredient(held):
		if _first_ingredient != "" and Inventory.add(_first_ingredient):
			_set_first_ingredient("")
		return
	if _first_ingredient == "":
		Inventory.remove(held)
		_set_first_ingredient(held)
		return
	var result := _find_result(_first_ingredient, held)
	# Erst prüfen, ob der Trank Platz hat, bevor Zutaten verschwinden.
	if not Inventory.has_room_for(result):
		print("Inventar voll")
		return
	Inventory.remove(held)
	Inventory.add(result)
	_set_first_ingredient("")


# Vorerst ist alles Geerntete eine Zutat. Später könnte das in den Item-Daten
# stehen (z. B. auch Kristalle aus Dungeons).
func _is_ingredient(item_id: String) -> bool:
	return item_id.begins_with("crop_")


func _find_result(first: String, second: String) -> String:
	for recipe in recipes:
		if recipe.matches(first, second):
			return recipe.result_item_id
	return FAILED_RESULT


func _set_first_ingredient(item_id: String) -> void:
	_first_ingredient = item_id
	ingredient_icon.texture = Inventory.icon_for(item_id)
