## Name der Hexe: im Intro eingegeben, im Spielstand gespeichert, auf dem
## Innendeckel des Grimoires in ihrer eigenen Tinte.
extends TestCase


func before_each() -> void:
	SaveGame.new_game()


func test_intro_asks_and_stores_name() -> void:
	var intro := (load("res://scenes/intro.tscn") as PackedScene).instantiate()
	tree.root.add_child(intro)
	await tree.process_frame
	intro.ask_name()
	check(intro._name_field != null and intro._name_field.has_focus(), "Eingabefeld erscheint mit Fokus")
	check_eq(intro._name_field.max_length, Grimoire.NAME_MAX_LENGTH, "Länge begrenzt")
	intro.store_name("  Nyx  ")
	check_eq(Grimoire.witch_name, "Nyx", "Name ohne Leerzeichen am Rand gespeichert")
	intro.queue_free()
	await tree.process_frame


func test_name_survives_save_and_load() -> void:
	Grimoire.witch_name = "Nyx"
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.collect()))
	SaveGame.new_game()
	check_eq(Grimoire.witch_name, "", "Neues Spiel ohne Namen")
	SaveGame._apply(data)
	check_eq(Grimoire.witch_name, "Nyx", "Name nach dem Laden wieder da")
	# Alter Spielstand ohne Namen und kaputte Werte.
	Grimoire.load_save_data({})
	check_eq(Grimoire.witch_name, "", "Alter Spielstand: kein Name")
	Grimoire.load_save_data({"witch_name": "Ein viel zu langer Name\nmit Umbruch"})
	check(Grimoire.witch_name.length() <= Grimoire.NAME_MAX_LENGTH and not Grimoire.witch_name.contains("\n"), "Gekürzt, ohne Umbruch")


func test_cover_shows_name() -> void:
	check(_cover_owner_text().contains(tr("COVER_OWNER")), "Ohne Namen der bisherige Satz")
	Grimoire.witch_name = "Nyx"
	var line := _cover_owner_text()
	check(line.contains("Nyx"), "Mit Namen steht er auf dem Innendeckel: " + line)


func _cover_owner_text() -> String:
	var cover := SpreadCover.new(null, load("res://data/grimoire/chapters/cover.tres"))
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	cover.build(left, right)
	var texts := left.find_children("*", "Label", true, false).map(func(l: Label) -> String: return tr(l.text))
	left.free()
	right.free()
	return "\n".join(PackedStringArray(texts))
