## Beute der Käfer: Jeder gereinigte Käfer lässt ein Bitterblütenblatt
## fallen, der Dornkäfer manchmal zusätzlich eine Blütenknospe
## (welt_und_items.md: Blütenknospen kommen von stärkeren Wesen).
extends TestCase


func test_horned_beetle_can_drop_bud() -> void:
	var horned := (load("res://scenes/world/blight_beetle_horned.tscn") as PackedScene).instantiate()
	check_eq(horned.rare_drop_item, "bloom_bud", "Dornkäfer: seltene Beute ist die Blütenknospe")
	check(horned.rare_drop_chance > 0.0 and horned.rare_drop_chance < 1.0, "Nur manchmal, nicht immer")
	horned.free()
	var plain := (load("res://scenes/world/blight_beetle.tscn") as PackedScene).instantiate()
	check_eq(plain.rare_drop_item, "", "Normaler Käfer hat keine seltene Beute")
	plain.free()


func test_drops_on_cleanse() -> void:
	check_eq(await _drops_after_cleanse(1.0), ["bitterbloom_petal", "bloom_bud"], "Chance 1: Blatt und Knospe")
	check_eq(await _drops_after_cleanse(0.0), ["bitterbloom_petal"], "Chance 0: nur das Blatt")


func _drops_after_cleanse(chance: float) -> Array:
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var beetle := (load("res://scenes/world/blight_beetle_horned.tscn") as PackedScene).instantiate()
	beetle.rare_drop_chance = chance
	holder.add_child(beetle)
	await tree.process_frame
	beetle._cleanse()
	var items := holder.get_children().filter(func(n: Node) -> bool: return n is DroppedItem) \
			.map(func(d: DroppedItem) -> String: return d.item_id)
	holder.queue_free()
	await tree.process_frame
	return items
