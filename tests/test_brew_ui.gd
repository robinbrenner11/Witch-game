## Brau-Fenster: lädt in jeder Reihenfolge (früher Kreis BrewSlot ↔ BrewWindow)
## und hat Platz für 4 Zutaten (Kessel-Upgrade bei Gnarl).
extends TestCase

const HELPER := "res://tests/helpers/load_brew_slot_first.gd"
# Breite des Kessel-Bereichs links im Fenster (1×-Pixel, rechts beginnt die Liste).
const CAULDRON_AREA := 124


## Nur ein frischer Godot-Prozess zeigt den Fehler: Im laufenden Test ist
## alles längst geladen. Deshalb startet der Test Godot ein zweites Mal.
func test_slot_loads_first_without_error() -> void:
	var output: Array = []
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", HELPER]
	var code := OS.execute(OS.get_executable_path(), args, output, true)
	var text := "\n".join(PackedStringArray(output))
	check_eq(code, 0, "Hilfsprozess endet normal")
	check(text.contains("BREW_SLOT_LOADED true"), "Brau-Feld lädt als Erstes")
	check(not text.contains("Parse Error"), "Kein Parse-Fehler beim Laden: " + text.left(300))


func test_four_slots_fit() -> void:
	var window := (load("res://scenes/ui/brew_window.tscn") as PackedScene).instantiate() as BrewWindow
	var rects: Array[Rect2] = []
	for i in 4:
		var rect := Rect2(window._slot_position(i, 4), Vector2(20, 20))
		check(rect.position.x >= 0 and rect.end.x <= CAULDRON_AREA, "Feld %d liegt im Kessel-Bereich (%s)" % [i, rect])
		for other in rects:
			check(not rect.intersects(other), "Feld %d überlappt ein anderes" % i)
		rects.append(rect)
	window.free()
