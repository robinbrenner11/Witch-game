## Lange Schatten bei zunehmendem Mond: Der Schatten der Hexe zeigt draußen
## auf die nächste lose Seite oder auf Reifes, das noch nie gesammelt wurde.
extends TestCase


class Lure:
	extends Node2D
	var secret := true

	func is_secret() -> bool:
		return secret


var shadow: LongShadow
var holder: Node2D


func before_each() -> void:
	SaveGame.new_game()
	holder = Node2D.new()
	tree.root.add_child(holder)
	shadow = LongShadow.new()
	holder.add_child(shadow)


func after_each() -> void:
	holder.queue_free()
	await tree.process_frame


func _lure(at: Vector2, secret: bool = true) -> Lure:
	var lure := Lure.new()
	lure.secret = secret
	lure.add_to_group(LongShadow.GROUP)
	holder.add_child(lure)
	lure.global_position = at
	return lure


func test_only_on_waxing_moon() -> void:
	check(not shadow.is_active(), "Neumond (Nacht 1): kein langer Schatten")
	DayCycle.day = 2
	check(shadow.is_active(), "Zunehmender Mond (Nacht 2): aktiv")
	DayCycle.day = 4
	check(not shadow.is_active(), "Halbmond: wieder normal")


func test_points_to_nearest_secret() -> void:
	var far := _lure(Vector2(300, 0))
	var near := _lure(Vector2(0, 120))
	var _known := _lure(Vector2(40, 0), false)
	var _out_of_range := _lure(Vector2(LongShadow.RANGE + 50, 0))
	check_eq(shadow.find_target(), near, "Nächstes Geheimnis, Bekanntes zählt nicht")
	near.secret = false
	check_eq(shadow.find_target(), far, "Gefunden: zeigt auf das nächste")
	far.secret = false
	check(shadow.find_target() == null, "Nichts mehr in Reichweite")


func test_forage_secret_until_first_pick() -> void:
	var morel := (load("res://scenes/world/wild/ember_morel.tscn") as PackedScene).instantiate() as Forage
	holder.add_child(morel)
	check(morel.is_in_group(LongShadow.GROUP), "Sammelbares lockt den Schatten")
	check(morel.is_secret(), "Noch nie gesammelt: Geheimnis")
	Grimoire.report("forage", {"id": morel.drop_item_id})
	check(not morel.is_secret(), "Einmal gesammelt: kein Geheimnis mehr")


func test_mother_moss_hints_on_waxing_moon() -> void:
	for flag in ["met_mother_moss", "dlg_mother_moss_first_meeting"]:
		WorldState.set_flag(flag)
	DayCycle.day = 2
	var talk := DialogueData.pick("mother_moss", "")
	check(talk != null and talk.id == "moon_waxing", "Mother Moss erzählt bei zunehmendem Mond vom Schatten")
