## Hexenpfade, deren Kartentext jetzt auch wirkt: Volatil (Wurftränke platzen
## weiter), Nachhall (Zonen halten länger), Nachtschatten-Bändigerin (Kuppel
## schadet nicht), Sucherin (Seiten glimmen weiter).
extends TestCase


func before_each() -> void:
	SaveGame.new_game()


## Wählt einen Pfad so, als hätte die Hexe die Stufe dafür erreicht (bei
## Stufe-10-Pfaden vorher den nötigen Stufe-5-Pfad).
func _choose(discipline_id: String, path_id: String) -> void:
	var path := PathData.from_id(path_id)
	Grimoire.add_xp(discipline_id, 100000)
	if path.requires_path_id != "":
		Grimoire.choose_path(PathData.from_id(path.requires_path_id))
	Grimoire.choose_path(path)
	check_eq(Grimoire.chosen_path(discipline_id, path.level), path_id, "Pfad %s gewählt" % path_id)


func test_volatile_and_lingering() -> void:
	var bomb := ItemData.from_id("potion_ember_bomb")
	var mist := ItemData.from_id("potion_thorn_mist")
	var radius := CombatPotions.throw_radius(bomb)
	var time := CombatPotions.zone_time(mist)
	check_eq(radius, bomb.throw_radius, "Ohne Pfad normaler Wirkkreis")
	_choose("brewing", "brewing_volatile")
	check(CombatPotions.throw_radius(bomb) > radius, "Volatil: Wurftränke platzen weiter")
	SaveGame.new_game()
	_choose("brewing", "brewing_lingering")
	check(CombatPotions.zone_time(mist) > time, "Nachhall: Dornennebel hält länger")


func test_nightshade_tamer() -> void:
	var shade := Vector2i(10, 10)
	var neighbour := Vector2i(11, 10)
	for cell in [shade, neighbour]:
		Garden.add_bed(cell)
	Garden.plant_seed(shade, "nightshade")
	Garden.plant_seed(neighbour, "mandrake")
	for i in 6:
		Garden.grow(shade)
	check(Garden.is_growth_blocked(neighbour), "Ohne Pfad hemmt der Nachtschatten den Nachbarn")
	_choose("herbalism", "herbalism_nightshade_tamer")
	check(not Garden.is_growth_blocked(neighbour), "Bändigerin: Kuppel schadet nicht mehr")


func test_seeker_glow() -> void:
	var page := (load("res://scenes/world/loose_page.tscn") as PackedScene).instantiate()
	page.page_id = "page_journal_01"
	tree.root.add_child(page)
	var normal: float = (page.get_node("Glimmer") as PointLight2D).texture_scale
	page.queue_free()
	_choose("wildcraft", "wildcraft_seeker")
	var seeker_page := (load("res://scenes/world/loose_page.tscn") as PackedScene).instantiate()
	seeker_page.page_id = "page_journal_01"
	tree.root.add_child(seeker_page)
	check((seeker_page.get_node("Glimmer") as PointLight2D).texture_scale > normal, "Sucherin: Seiten glimmen weiter")
	seeker_page.queue_free()
	await tree.process_frame
