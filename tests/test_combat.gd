## Kampf-Grundlagen als Regressionstest: Käfer nehmen Treffer, taumeln,
## werden bei null Leben gereinigt (Beute, Grimoire), Dornkäfer halten mehr
## aus, Zauber und Hiebe der Digitalis-Formen treffen, die Hexe nimmt
## Schaden und ist danach kurz unverwundbar.
extends TestCase

var holder: Node2D


func before_each() -> void:
	SaveGame.new_game()


func _spawn(scene: String) -> BlightBeetle:
	holder = Node2D.new()
	tree.root.add_child(holder)
	var beetle := (load(scene) as PackedScene).instantiate() as BlightBeetle
	holder.add_child(beetle)
	return beetle


func _cleanup() -> void:
	holder.queue_free()
	await tree.process_frame


func test_beetle_hit_and_cleanse() -> void:
	var beetle := _spawn("res://scenes/world/blight_beetle.tscn")
	await tree.process_frame
	check(beetle.is_in_group("blighted"), "Käfer gehört zu den Befallenen")
	var start := beetle.health
	beetle.take_hit(1, Vector2.RIGHT * 90.0)
	check_eq(beetle.health, start - 1, "Ein Treffer kostet ein Leben")
	check_eq(beetle.state, BlightBeetle.State.STAGGER, "Treffer bringt ihn aus dem Tritt")
	beetle.take_hit(start, Vector2.ZERO)
	check_eq(beetle.state, BlightBeetle.State.CLEANSED, "Bei null Leben gereinigt")
	check(not beetle.is_in_group("blighted"), "Gereinigt nicht mehr befallen")
	check_eq(Grimoire.count_of("cleanse/blight_beetle"), 1, "Grimoire erfährt von der Reinigung")
	var drops := holder.get_children().filter(func(n: Node) -> bool: return n is DroppedItem)
	check_eq(drops.size(), 1, "Ein Blütenblatt bleibt liegen")
	beetle.take_hit(5, Vector2.ZERO)
	check_eq(drops.size(), holder.get_children().filter(func(n: Node) -> bool: return n is DroppedItem).size(),
			"Gereinigte Käfer nehmen keine Treffer mehr (keine doppelte Beute)")
	await _cleanup()


func test_horned_beetle_is_tougher() -> void:
	var plain := (load("res://scenes/world/blight_beetle.tscn") as PackedScene).instantiate() as BlightBeetle
	var horned := (load("res://scenes/world/blight_beetle_horned.tscn") as PackedScene).instantiate() as BlightBeetle
	check(horned.max_health > plain.max_health, "Dornkäfer hat mehr Leben")
	check(horned.charges > plain.charges, "Dornkäfer läuft öfter an")
	plain.free()
	horned.free()


func test_damage_over_time_does_not_stagger() -> void:
	var beetle := _spawn("res://scenes/world/blight_beetle_horned.tscn")
	await tree.process_frame
	var state_before := beetle.state
	beetle.take_hit(1, Vector2.ZERO, false)
	check_eq(beetle.state, state_before, "Schaden über Zeit (Dornennebel) bringt nicht aus dem Tritt")
	await _cleanup()


func test_every_attack_hurts() -> void:
	for form_id in Grimoire.START_FORMS:
		for level in [1, 2]:
			var form := DigitalisForm.at_level(form_id, level)
			for attack: AttackData in [form.light, form.heavy]:
				check(attack.damage > 0, "%s Stufe %d: Angriff macht Schaden" % [form_id, level])
				check(attack.power_cost > 0.0, "%s Stufe %d: Angriff kostet Hexenkraft" % [form_id, level])
				check(attack.cooldown > 0.0, "%s Stufe %d: Angriff hat eine Abklingzeit" % [form_id, level])
			check(form.heavy.damage >= form.light.damage, "%s: stark mindestens so stark wie leicht" % form_id)


func test_witch_takes_damage_once_then_invulnerable() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	tree.root.add_child(player)
	await tree.process_frame
	var vitals := player.get_node("Vitals") as Vitals
	var start := vitals.health
	check(vitals.take_damage(2), "Treffer zählt")
	check_eq(vitals.health, start - 2, "Leben sinkt")
	vitals.make_invulnerable(0.8)
	check(not vitals.take_damage(2), "Direkt danach kurz unverwundbar")
	check_eq(vitals.health, start - 2, "Leben bleibt")
	player.queue_free()
	await tree.process_frame
