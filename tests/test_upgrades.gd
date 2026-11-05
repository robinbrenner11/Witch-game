## Upgrades bei Gnarl (Schritt 7, Teil 2): Stab II, Sichel II, Kessel mit
## 4 Plätzen. Tausch mit mehreren Materialien, Belohnung RewardData.UPGRADE,
## Stufen als eigene Datendateien.
extends TestCase

const STAFF_2 := preload("res://data/trades/gnarl/b_staff_2.tres")
const SICKLE_2 := preload("res://data/trades/gnarl/c_sickle_2.tres")
const CAULDRON_2 := preload("res://data/trades/gnarl/d_cauldron_2.tres")
# Breite einer Zeile in der Antwort-Auswahl der Dialogbox (Text minus Einzug).
const CHOICE_WIDTH := 278.0


## Ein Wesen zum Treffen, ohne echten Käfer.
class Dummy:
	extends Node2D
	var hits := 0

	func take_hit(_damage: int, _knockback: Vector2, _stagger: bool = true) -> void:
		hits += 1


func before_each() -> void:
	WorldState.reset()
	Inventory.reset()
	Grimoire.reset()
	Brewing.reset()


func test_offered_only_in_workshop() -> void:
	for offer in [STAFF_2, SICKLE_2, CAULDRON_2]:
		check(not offer.is_offered("gnarl"), "%s vor dem Umzug nicht angeboten" % offer.id)
	WorldState.set_flag("gnarl_moved")
	for offer in [STAFF_2, SICKLE_2, CAULDRON_2]:
		check(offer.is_offered("gnarl"), "%s in der Werkstatt angeboten" % offer.id)
		check(offer.needs_confirm(), "%s wird bestätigt" % offer.id)
	check_eq(TradeOffer.all_for("gnarl").size(), 4, "Gnarl hat Heiltrank-Gabe und 3 Upgrades")


func test_staff_upgrade() -> void:
	WorldState.set_flag("gnarl_moved")
	Inventory.add("cave_crystal", 2)
	Inventory.add("bitterbloom_petal", 2)
	check(not STAFF_2.trade("gnarl"), "Mit zu wenig Blättern geht es nicht")
	check_eq(Inventory.count("cave_crystal"), 2, "Nichts wurde genommen")
	check_eq(Grimoire.upgrade_level("staff"), 1, "Stab noch Stufe 1")
	Inventory.add("bitterbloom_petal", 1)
	check(STAFF_2.trade("gnarl"), "Mit allen Materialien klappt es")
	check_eq(Inventory.count("cave_crystal"), 0, "Kristalle verbraucht")
	check_eq(Inventory.count("bitterbloom_petal"), 0, "Blätter verbraucht")
	check_eq(Grimoire.upgrade_level("staff"), 2, "Stab Stufe 2")
	check(not STAFF_2.is_offered("gnarl"), "Danach nicht mehr angeboten")
	check(SICKLE_2.is_offered("gnarl"), "Sichel bleibt angeboten")


func test_forms_by_level() -> void:
	check_eq(DigitalisForm.at_level("staff", 1).heavy.pierce, 0, "Stab I durchschlägt nichts")
	check_eq(DigitalisForm.at_level("staff", 2).heavy.pierce, 1, "Stab II durchschlägt einen Gegner")
	check_eq(DigitalisForm.at_level("staff", 2).id, "staff", "Stab II bleibt die Form staff")
	check(not DigitalisForm.at_level("sickle", 1).heavy.cuts_vines, "Sichel I schneidet keine Ranken")
	check(DigitalisForm.at_level("sickle", 2).light.cuts_vines, "Sichel II schneidet Ranken (leicht)")
	check(DigitalisForm.at_level("sickle", 2).heavy.cuts_vines, "Sichel II schneidet Ranken (stark)")
	check_eq(DigitalisForm.at_level("staff", 5).heavy.pierce, 1, "Fehlende Stufe: die nächstniedrigere")


func test_cauldron_upgrade() -> void:
	WorldState.set_flag("gnarl_moved")
	check_eq(Brewing.capacity, 3, "Kessel fasst anfangs 3")
	Inventory.add("cave_crystal", 3)
	Inventory.add("willow_bark", 1)
	check(CAULDRON_2.trade("gnarl"), "Kessel-Upgrade klappt")
	check_eq(Brewing.capacity, 4, "Kessel fasst jetzt 4")
	check_eq(Grimoire.upgrade_level("cauldron"), 2, "Kessel Stufe 2")


func test_upgrades_saved() -> void:
	Grimoire.grant(SICKLE_2.reward)
	var saved := Grimoire.get_save_data()
	Grimoire.reset()
	check_eq(Grimoire.upgrade_level("sickle"), 1, "Nach reset Stufe 1")
	Grimoire.load_save_data(saved)
	check_eq(Grimoire.upgrade_level("sickle"), 2, "Nach Laden wieder Stufe 2")
	# Älterer Spielstand ohne Upgrades und kaputte Werte.
	Grimoire.load_save_data({"upgrades": "kaputt"})
	check_eq(Grimoire.upgrade_level("sickle"), 1, "Kaputter Spielstand: Stufe 1")
	# Ein Upgrade kann nie eine Stufe zurück.
	Grimoire.grant(SICKLE_2.reward)
	var lower := RewardData.new()
	lower.type = RewardData.Type.UPGRADE
	lower.target_id = "sickle"
	lower.value = 1
	Grimoire.grant(lower)
	check_eq(Grimoire.upgrade_level("sickle"), 2, "Keine Stufe zurück")


func test_pierce() -> void:
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var first := Dummy.new()
	var second := Dummy.new()
	for enemy in [first, second]:
		enemy.add_to_group("blighted")
		holder.add_child(enemy)
	second.position = Vector2(20, 0)
	var spell := Spell.new()
	spell.setup(DigitalisForm.at_level("staff", 2).heavy, Vector2.RIGHT)
	holder.add_child(spell)
	spell._on_body_entered(first)
	check_eq(first.hits, 1, "Erster Gegner getroffen")
	check(not spell._done, "Zauber fliegt weiter")
	spell.global_position = second.global_position
	spell._on_body_entered(second)
	check(spell._done, "Am zweiten Gegner platzt er")
	check_eq(second.hits, 1, "Zweiter Gegner getroffen")
	check_eq(first.hits, 1, "Der erste wird beim Platzen nicht noch einmal getroffen")
	holder.queue_free()
	await tree.process_frame


func test_sickle_cuts_vines() -> void:
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var gate := Gate.new()
	gate.required_flag = "test_vines_cut"
	gate.cut_open = true
	gate.size = Vector2(64, 64)
	gate.position = Vector2(40, 0)
	holder.add_child(gate)
	var plain := Gate.new()
	plain.required_flag = "test_plain"
	plain.position = Vector2(-40, 0)
	holder.add_child(plain)
	check(not plain.on_cut(), "Ein Gate ohne cut_open lässt sich nicht schneiden")

	var slash := Slash.new()
	slash.attack = DigitalisForm.at_level("sickle", 1).light
	slash.aim = Vector2.RIGHT
	holder.add_child(slash)
	slash._check_hits()
	check(not WorldState.has_flag("test_vines_cut"), "Sichel I schneidet die Ranken nicht")
	slash.attack = DigitalisForm.at_level("sickle", 2).light
	slash._check_hits()
	check(WorldState.has_flag("test_vines_cut"), "Sichel II schneidet die Ranken auf")
	check(gate.is_open(), "Gate offen")
	holder.queue_free()
	await tree.process_frame


func test_swamp_vines_can_be_cut() -> void:
	var lakewood := (load("res://scenes/world/lakewood_v2.tscn") as PackedScene).instantiate()
	var vines := lakewood.get_node_or_null("SwampVines") as Gate
	check(vines != null and vines.cut_open, "S4 lässt sich mit Sichel II schneiden")
	check(vines != null and vines.open_with_item == "potion_ember_bomb", "Glutbombe geht weiter")
	lakewood.free()


## Auswahlzeile in eine Zeile, Erklärung höchstens 3 Zeilen, auf Englisch und Deutsch.
func test_texts_fit() -> void:
	var box := (load("res://scenes/ui/dialogue_box.tscn") as PackedScene).instantiate() as DialogueBox
	tree.root.add_child(box)
	await tree.process_frame
	var font := box.text_label.get_theme_font("font")
	var font_size := box.text_label.get_theme_font_size("font_size")
	var old_locale := TranslationServer.get_locale()
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for offer in [STAFF_2, SICKLE_2, CAULDRON_2]:
			var width := font.get_string_size(offer.label(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			check(width <= CHOICE_WIDTH, "Auswahl zu breit (%s): %s" % [locale, offer.label()])
			for line in offer.detail_lines():
				box.text_label.text = tr(line)
				box.text_label.visible_characters = -1
				check(box.text_label.get_line_count() <= 3, "Zu lang (%s): %s" % [locale, tr(line)])
	TranslationServer.set_locale(old_locale)
	box.queue_free()
	await tree.process_frame
