## Die ersten Minuten, gespielt über simulierte Tasten im echten Spiel
## (main.tscn): zum Pult laufen und das Buch nehmen, das Buch öffnen und
## schließen, durch die Tür in den Garten, dort die Erde wecken und säen.
## Prüft Steuerung, Kollision, Interaktion und Ortswechsel zusammen.
extends TestCase

# Schneller als Echtzeit, damit der Test nicht ewig läuft.
const SPEED := 3.0
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]

var main: Node
var player: Player


func before_each() -> void:
	SaveGame.new_game()


func test_first_minutes() -> void:
	Engine.time_scale = SPEED
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	player = main.player
	await _frames(10)

	# 1. Zum Pult und das Buch nehmen.
	var lectern := main.level.get_node("Objects/Lectern") as Node2D
	check(await _walk_to(lectern.global_position + Vector2(0, 26)), "Hexe kommt zum Pult")
	await _face(Vector2.UP)
	await _press("interact")
	await _frames(10)
	check(Grimoire.has_book, "Buch per E vom Pult genommen")

	# 2. Buch mit der Buch-Taste öffnen und wieder schließen.
	var book := tree.get_first_node_in_group("grimoire_book") as GrimoireBook
	await _press("book")
	await _frames(10)
	check(book.visible, "Buch geht mit der Buch-Taste auf")
	await _press("book")
	await _frames(20)
	check(not book.visible, "Buch geht wieder zu")

	# 3. Durch die Tür nach draußen in den Garten.
	var door := main.level.get_node("ToGarden") as Node2D
	await _walk_to(door.global_position, 6.0, 8.0)
	await _frames(90)
	check_eq(String(main.level.name), "Garden", "Durch die Tür im Garten angekommen")

	# 4. Vor einem freien Stück Gartenerde die Erde wecken und säen.
	if String(main.level.name) == "Garden":
		var spot := _free_soil_spot()
		check(spot != Vector2.INF, "Freie Gartenerde gefunden")
		if spot != Vector2.INF:
			# Durchs Gartentor, wie eine Spielerin auch (der Zaun ist sonst zu).
			var gate := main.level.get_node("Objects/GateShelter") as Node2D
			await _walk_to(gate.global_position + Vector2(0, -14), 4.0, 6.0)
			check(await _walk_to(gate.global_position + Vector2(0, 30), 4.0, 6.0), "Hexe geht durchs Gartentor")
			var reached := await _walk_to(spot + Vector2(0, 30), 4.0, 10.0)
			if not reached:
				print("DBG Garten: Hexe bei ", player.global_position, " Ziel ", spot + Vector2(0, 30))
			check(reached, "Hexe kommt zur Gartenerde")
			await _face(Vector2.UP)
			var cell := Garden.cell_at(player.interaction_area.global_position)
			await _press("snap")
			await _frames(40)
			check(Garden.has_bed(cell), "Erde mit dem Schnippen geweckt")
			var seeds := Inventory.count(Inventory.selected_item_id())
			await _press("interact")
			await _frames(40)
			check(Garden.has_plant(cell), "Samen per E gesät")
			check_eq(Inventory.count("seed_mandrake"), seeds - 1, "Ein Samen verbraucht")
	Engine.time_scale = 1.0
	main.queue_free()
	await _frames(2)


# --- Hilfen ---------------------------------------------------------------

func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


## Läuft mit den Bewegungstasten zum Ziel. false, wenn sie nicht ankommt
## (hängt fest oder läuft zu lange).
func _walk_to(target: Vector2, tolerance: float = 4.0, timeout: float = 6.0) -> bool:
	var waited := 0.0
	var arrived := false
	while waited < timeout * 60.0:
		var offset := target - player.global_position
		if offset.length() <= tolerance:
			arrived = true
			break
		_hold(offset.normalized())
		await tree.physics_frame
		waited += 1.0
		if not is_instance_valid(player):
			break
	_hold(Vector2.ZERO)
	await _frames(2)
	return arrived


func _hold(direction: Vector2) -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	if direction.x < -0.2:
		Input.action_press("move_left", -direction.x)
	elif direction.x > 0.2:
		Input.action_press("move_right", direction.x)
	if direction.y < -0.2:
		Input.action_press("move_up", -direction.y)
	elif direction.y > 0.2:
		Input.action_press("move_down", direction.y)


## Einen Schritt in eine Richtung antippen, damit die Hexe dorthin schaut.
func _face(direction: Vector2) -> void:
	_hold(direction)
	await _frames(2)
	_hold(Vector2.ZERO)
	await _frames(2)


func _press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	tree.root.push_input(down)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	tree.root.push_input(up)
	await _frames(2)


## Eine Zelle Gartenerde ohne Beet und ohne Pflanze, mit freier Zelle darunter
## zum Hinstellen.
func _free_soil_spot() -> Vector2:
	var level := main.level as Level
	for x in range(10, 30):
		for y in range(8, 16):
			var cell := Vector2i(x, y)
			var below := cell + Vector2i(0, 1)
			if level.allows_bed_at(cell) and not Garden.has_bed(cell) and not Garden.has_bed(below) \
					and level.allows_bed_at(below):
				return Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0
	return Vector2.INF
