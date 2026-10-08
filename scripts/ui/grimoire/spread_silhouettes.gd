class_name SpreadSilhouettes
extends GrimoireSpread

## Kapitel, deren Spielsystem es noch nicht gibt (Digitalis, People): ein
## Raster aus Silhouetten mit kleinen Hinweisen. So sieht man schon, dass da
## etwas kommt. Wird ersetzt, sobald es Digitalis-Formen und NPCs gibt.

# Kapitel-ID -> Liste von [Schlüssel Name, Schlüssel Hinweis].
const ENTRIES := {
	"digitalis": [
		["DIGITALIS_STAFF", "DIGITALIS_STAFF_HINT"],
		["DIGITALIS_SICKLE", "DIGITALIS_GNARL_HINT"],
		["DIGITALIS_THORNWHIP", "DIGITALIS_GNARL_HINT"],
		["DIGITALIS_ROOTMAUL", "DIGITALIS_GNARL_HINT"],
	],
	"people": [
		["???", "PEOPLE_NOT_MET"], ["???", "PEOPLE_NOT_MET"], ["???", "PEOPLE_NOT_MET"],
		["???", "PEOPLE_NOT_MET"], ["???", "PEOPLE_NOT_MET"],
	],
}

var _selected := 0


func build(left: Control, right: Control) -> void:
	add_title(left)
	var entries: Array = ENTRIES.get(chapter.id, [])
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	for i in entries.size():
		var slot := BookSlot.new()
		slot.state = BookSlot.State.UNKNOWN
		slot.selected = i == _selected
		slot.data = i
		slot.chosen.connect(func(s: BookSlot) -> void:
			_selected = s.data
			book.refresh())
		grid.add_child(slot)
	left.add_child(grid)
	if _selected < entries.size():
		# Unbekannte Formen kennt man noch nicht beim Namen.
		right.add_child(BookStyle.heading("???", BookStyle.INK_FAINT, text_width))
		right.add_child(BookStyle.label(entries[_selected][1], BookStyle.INK_FAINT, text_width))
