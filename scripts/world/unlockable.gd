extends Node2D

## Zeigt seine Kinder nur, wenn eine Bedingung erfüllt ist, z. B. Marktstände
## bei Halbmond oder etwas, das erst nach einer Freischaltung da ist. Ist die
## Bedingung nicht erfüllt, sind die Kinder unsichtbar und ihre Kollisionen
## aus. Neu geprüft wird bei jeder neuen Nacht und jedem neuen Flag.
## (Baustein M8 aus docs/archiv/dorf_hub_plan.md.)

## Nur sichtbar mit diesem Flag (leer = egal).
@export var required_flag: String = ""
## Nur in diesen Mondphasen (Moon.Phase), leer = egal.
@export var moon_phases: Array[int] = []


func _ready() -> void:
	DayCycle.day_passed.connect(func(_day: int) -> void: _apply())
	WorldState.flag_changed.connect(func(_flag: String) -> void: _apply())
	_apply()


func is_unlocked() -> bool:
	if required_flag != "" and not WorldState.has_flag(required_flag):
		return false
	return moon_phases.is_empty() or Moon.phase() in moon_phases


func _apply() -> void:
	var on := is_unlocked()
	visible = on
	for shape in find_children("*", "CollisionShape2D", true, false):
		(shape as CollisionShape2D).set_deferred("disabled", not on)
