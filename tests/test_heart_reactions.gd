## Nach dem ersten Blütenherz reagieren die Leute darauf, und vorher erzählt
## der Nachtwächter vom Nebel vor dem Turm (mit Zutaten-Hinweis).
extends TestCase


func before_each() -> void:
	SaveGame.new_game()


func test_watchman_tells_of_the_mist() -> void:
	WorldState.set_flag("met_watchman")
	WorldState.set_flag("met_gnarl")
	WorldState.set_flag("dlg_watchman_first_meeting")
	for dialogue in DialogueData.all_for("watchman"):
		if dialogue.topic == "rumor" and dialogue.id != "rumor_mist":
			WorldState.set_flag(dialogue.said_flag("watchman"))
	var rumor := DialogueData.pick("watchman", "rumor")
	check(rumor != null and rumor.id == "rumor_mist", "Gerücht über den Nebel")
	WorldState.set_flag("bloom_heart_1_cleansed")
	rumor = DialogueData.pick("watchman", "rumor")
	check(rumor == null or rumor.id != "rumor_mist", "Kein Nebel-Gerücht mehr nach dem Herz")


func test_people_react_to_the_heart() -> void:
	for flag in ["met_watchman", "met_mother_moss", "met_gnarl", "gnarl_helped", "bloom_heart_1_cleansed"]:
		WorldState.set_flag(flag)
	for npc_id in ["watchman", "mother_moss", "gnarl"]:
		var found := false
		for dialogue in DialogueData.all_for(npc_id):
			if dialogue.id == "heart_cleansed":
				found = dialogue.requires_flags.all(func(flag: String) -> bool: return WorldState.has_flag(flag))
		check(found, "%s hat etwas zum Blütenherz zu sagen" % npc_id)
