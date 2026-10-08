class_name SpreadCover
extends GrimoireSpread

## Innendeckel: links Vesperas Notiz mit den ersten Zielen (durchgestrichen,
## sobald erledigt), rechts die Hand mit den Fingerspitzen, die mit der
## Hexenstärke dunkler werden (Summe der Disziplin-Stufen, kommt mit G3).

const NOTE_KEY := "BOOK_NOTE_START"
const GOAL_KEYS := {
	"plant": "GOAL_PLANT",
	"brew": "GOAL_BREW",
	"sleep": "GOAL_SLEEP",
	"wake": "GOAL_WAKE",
}


func build(left: Control, right: Control) -> void:
	var note := RichTextLabel.new()
	note.bbcode_enabled = true
	note.fit_content = true
	note.scroll_active = false
	note.custom_minimum_size.x = text_width
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_theme_color_override("default_color", BookStyle.INK_VESPERA)
	# Zusammengesetzter Text, deshalb tr() von Hand: Godot übersetzt nur
	# Texte automatisch, die genau ein Schlüssel sind.
	var text := tr(NOTE_KEY)
	for goal in Grimoire.GOALS:
		var line := tr(GOAL_KEYS[goal])
		if Grimoire.is_goal_done(goal):
			line = "[s][color=#%s]%s[/color][/s]" % [BookStyle.INK_FAINT.to_html(false), line]
		text += "\n" + line
	note.text = text
	left.add_child(note)

	right.add_child(BookStyle.heading("COVER_STRENGTH", BookStyle.INK_VESPERA_TITLE, text_width))
	var hand := WitchHand.new()
	hand.custom_minimum_size = Vector2(text_width, 150)
	hand.strength = Grimoire.witch_strength()
	right.add_child(hand)
	right.add_child(BookStyle.label("COVER_OWNER", BookStyle.INK_PLAYER, text_width))


## Platzhalter-Zeichnung der Hand, bis die Grafik da ist: Fingerspitzen werden
## in 5 Stufen dunkler.
class WitchHand:
	extends Control

	const SKIN := Color("#6B3F33")
	const TIPS: Array[Color] = [
		Color("#6B3F33"), Color("#4A2B27"), Color("#33201F"), Color("#221418"), Color("#0E0A14"),
	]
	var strength := 0

	func _draw() -> void:
		var center := Vector2(size.x / 2.0, size.y - 10)
		var palm := Rect2(center + Vector2(-22, -48), Vector2(44, 48))
		draw_rect(palm.grow(1), BookStyle.AUBERGINE)
		draw_rect(palm, SKIN)
		var stage := clampi(strength / 5, 0, TIPS.size() - 1)
		# Vier Finger und ein Daumen, jede Stufe färbt die Spitzen weiter ein.
		var fingers := [[-20, 40], [-9, 50], [2, 52], [13, 44]]
		for f in fingers:
			var rect := Rect2(center + Vector2(f[0], -48 - f[1]), Vector2(9, f[1]))
			draw_rect(rect.grow(1), BookStyle.AUBERGINE)
			draw_rect(rect, SKIN)
			draw_rect(Rect2(rect.position, Vector2(9, 8 + stage * 3)), TIPS[stage])
		var thumb := Rect2(center + Vector2(22, -40), Vector2(18, 9))
		draw_rect(thumb.grow(1), BookStyle.AUBERGINE)
		draw_rect(thumb, SKIN)
		draw_rect(Rect2(thumb.end.x - 6 - stage * 2, thumb.position.y, 6 + stage * 2, 9), TIPS[stage])
		# Goldener Armreif wie bei der Hexe.
		draw_rect(Rect2(center + Vector2(-23, -2), Vector2(46, 3)), BookStyle.GOLD)
