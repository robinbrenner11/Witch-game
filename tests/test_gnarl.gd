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
