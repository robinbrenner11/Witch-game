class_name Interactable
extends Area2D

## Baustein für alles, womit die Hexe per E interagieren kann (Beet, später
## Truhe, Tür, NPC …). Er meldet die Interaktion nur per Signal – was dann
## passiert, entscheidet die Szene, in der er steckt.
##
## Was E hier gerade tun würde ("Ernten", "Schlafen" …), zeigt der
## Interaktions-Hinweis neben den Goldklammern an. Den Text liefert die Szene
## selbst über eine Methode interaction_prompt(), weil er oft vom Zustand
## abhängt (Beet: pflanzen, ernten oder ausgießen). Ohne diese Methode gilt
## der feste Wert prompt.

signal interacted(player: Node2D)

## Schlüssel in data/translations/texts.csv, z. B. "PROMPT_SLEEP". Leer = nur
## die Klammern, kein Text.
@export var prompt: String = ""


func _ready() -> void:
	# Fest im Code statt in jeder Szene, damit man es beim Einbauen nicht
	# vergessen kann: Interactables liegen auf Layer 2 und suchen selbst nichts.
	collision_layer = 2
	collision_mask = 0
	monitoring = false


func interact(player: Node2D) -> void:
	interacted.emit(player)


## Schlüssel des Hinweistexts für den jetzigen Zustand ("" = keiner).
func prompt_key() -> String:
	var owner_node := get_parent()
	if owner_node and owner_node.has_method("interaction_prompt"):
		return owner_node.interaction_prompt()
	return prompt
