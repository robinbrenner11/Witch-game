## Gnarl: sitzt im tiefen Wald, bis man ihm hilft, und zieht dann mit der
## nächsten Nacht in die Werkstatt im Dorf. Dazu die Hinweise des Nachtwächters.
extends TestCase

const GNARL := preload("res://data/npcs/gnarl.tres")
# Mitten in der Nacht (22 Uhr), damit ein Block aktiv ist.
const NIGHT_TIME := 22 * 60.0


func before_each() -> void:
	WorldState.reset()
	Inventory.reset()
	Grimoire.reset()
	DayCycle.reset()


func test_lives_in_forest_until_moved() -> void:
	var entry := GNARL.entry_at(NIGHT_TIME)
	check(entry != null and entry.level == "Forest", "Anfangs im Wald")
	WorldState.set_flag("gnarl_moved")
	entry = GNARL.entry_at(NIGHT_TIME)
	check(entry != null and entry.level == "Village", "Nach dem Umzug im Dorf")
	check_eq(entry.spot if entry else "", "Workshop", "Spot an der Werkstatt")


## Der Nachtwächter weist auf die Kerze im Wald hin, solange man Gnarl nicht
## kennt, und bemerkt später das Licht in der Werkstatt.
func test_watchman_points_to_gnarl() -> void:
	WorldState.set_flag("met_watchman")
	WorldState.set_flag("dlg_watchman_first_meeting")
	# Gerüchte über Rezepte haben Vorrang; hier sind sie schon erzählt.
	for dialogue in DialogueData.all_for("watchman"):
		if dialogue.topic == "rumor" and dialogue.id != "rumor_gnarl":
			WorldState.set_flag("dlg_watchman_" + dialogue.id)
	var rumor := DialogueData.pick("watchman", "rumor")
	check(rumor != null and rumor.id == "rumor_gnarl", "Gerücht über die Kerze im Wald")
	WorldState.set_flag("met_gnarl")
	rumor = DialogueData.pick("watchman", "rumor")
	check(rumor == null or rumor.id != "rumor_gnarl", "Kein Gerücht mehr, wenn man Gnarl kennt")
	WorldState.set_flag("gnarl_moved")
	var line := DialogueData.pick("watchman", "")
	check(line != null and line.id == "workshop_light", "Wächter bemerkt das Licht in der Werkstatt")


## Nach jedem Upgrade hat Gnarl beim nächsten Gespräch etwas dazu zu sagen.
func test_gnarl_reacts_to_upgrade() -> void:
	WorldState.set_flag("met_gnarl")
	WorldState.set_flag("gnarl_helped")
	WorldState.set_flag("gnarl_moved")
	# Alle anderen einmaligen Gespräche sind längst erzählt.
	for dialogue in DialogueData.all_for("gnarl"):
		if dialogue.once and not dialogue.id.begins_with("upgraded_"):
			WorldState.set_flag(dialogue.said_flag("gnarl"))
	for path in ["b_staff_2", "c_sickle_2", "d_cauldron_2"]:
		var offer := load("res://data/trades/gnarl/%s.tres" % path) as TradeOffer
		check(offer.sets_flag != "", "%s setzt ein Flag für die Reaktion" % offer.id)
		Inventory.add(offer.wants_item, offer.wants_amount)
		if offer.also_wants_item != "":
			Inventory.add(offer.also_wants_item, offer.also_wants_amount)
		check(offer.trade("gnarl"), "%s klappt" % offer.id)
		var reaction := DialogueData.pick("gnarl", "workshop")
		check(reaction != null and reaction.requires_flags.has(offer.sets_flag), "Gnarl reagiert auf %s" % offer.id)
		if reaction:
			WorldState.set_flag(reaction.said_flag("gnarl"))
