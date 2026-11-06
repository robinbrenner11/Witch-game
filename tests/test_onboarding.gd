## Einstieg: Die ersten Ziele stehen in sinnvoller Reihenfolge im Buch, das
## Lesepult zieht den Blick an, solange das Buch dort liegt, und Texte nennen
## Tasten nie fest (sonst stimmen sie nach dem Umbelegen nicht mehr).
extends TestCase

# Eine Taste in Klammern oder "drück X" mitten im Text, z. B. "(R)" oder "(Tab)".
const HARDCODED_KEY := "\\((?:[A-Z]|Tab|Shift|Space|Esc|F\\d{1,2})\\)"


func before_each() -> void:
	Grimoire.reset()


func test_goal_order() -> void:
	var goals := Grimoire.GOALS
	check(goals.find("wake") < goals.find("plant"), "Erde wecken vor dem Pflanzen")
	check(goals.find("plant") < goals.find("brew"), "Pflanzen vor dem Brauen")
	check_eq(goals.back(), "sleep", "Schlafen zuletzt")


func test_no_hardcoded_keys_in_texts() -> void:
	var regex := RegEx.create_from_string(HARDCODED_KEY)
	var file := FileAccess.open("res://data/translations/texts.csv", FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		for i in range(1, row.size()):
			check(regex.search(row[i]) == null, "Taste fest im Text: %s (%s)" % [row[0], row[i]])


func test_wake_goal_names_current_key() -> void:
	var cover := SpreadCover.new(null, load("res://data/grimoire/chapters/cover.tres"))
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	cover.build(left, right)
	var note := left.find_children("*", "RichTextLabel", true, false)[0] as RichTextLabel
	var key := InputHints.key_for("snap")
	check(key != "", "Taste für das Schnippen gefunden")
	check(note.text.contains("(%s)" % key), "Ziel nennt die belegte Taste: " + note.text.right(120))
	check(not note.text.contains("%s"), "Kein offener Platzhalter")
	left.free()
	right.free()


func test_lectern_glows_until_book_taken() -> void:
	var lectern := (load("res://scenes/world/lectern.tscn") as PackedScene).instantiate()
	tree.root.add_child(lectern)
	await tree.process_frame
	check(lectern.is_glowing(), "Pult glimmt, solange das Buch daliegt")
	Grimoire.find_book()
	check(not lectern.is_glowing(), "Kein Glimmen mehr, wenn das Buch genommen ist")
	lectern.queue_free()
	await tree.process_frame
