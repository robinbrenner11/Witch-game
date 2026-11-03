## Hilfsskript für test_brew_ui: lädt das Brau-Feld als Allererstes, in einem
## frischen Godot-Prozess. Genau diese Reihenfolge löste früher einen
## Parse-Fehler aus (BrewSlot ↔ BrewWindow verwiesen im Kreis aufeinander).
## Absichtlich ohne Typen aus dem Spiel, damit beim Start nichts vorab lädt.
extends SceneTree


func _initialize() -> void:
	# Erst einen Frame warten, damit die Autoloads bereit sind.
	await process_frame
	var slot_script := load("res://scripts/ui/brew_slot.gd")
	var slot := load("res://scenes/ui/brew_slot.tscn") as PackedScene
	var window := load("res://scenes/ui/brew_window.tscn") as PackedScene
	var ok := slot_script != null and slot != null and window != null and slot.instantiate().get_script() != null
	print("BREW_SLOT_LOADED " + str(ok))
	quit()
