class_name Vitals
extends Node

## Leben und Hexenkraft der Hexe. Hexenkraft bezahlt kleine Zauber und den
## Dash; sie erholt sich langsam, Tränke füllen sie auf. Die größte Menge
## wächst mit der Hexenstärke aus dem Grimoire. Schlafen heilt alles.
## Design: docs/design/game_design.md, Abschnitte 6 (Magie) und 7 (Kampf).

signal changed
## Leben auf null: Die Nacht endet (siehe Combat).
signal died
## Ein Treffer hat gezählt (für Rückmeldung wie Aufblitzen, siehe VitalsFeedback).
signal damaged(amount: int, source: String)
signal healed(amount: int)

const BASE_MAX_POWER := 8
# Pro so viel Hexenstärke ein Punkt mehr Hexenkraft.
const STRENGTH_PER_POWER := 2

@export var max_health: int = 10
# Hexenkraft pro Sekunde, die von selbst zurückkommt.
@export var power_regen: float = 0.5

var health: int = 10
var power: float = 0.0
# Sekunden, die die Hexe noch unverwundbar ist (nach Dash oder Treffer).
var _invulnerable := 0.0
# Woher der letzte Schaden kam ("" = Kampf, "sun" = Sonne).
var last_damage_source := ""


func _ready() -> void:
	health = max_health
	power = max_power()
	DayCycle.day_passed.connect(func(_day: int) -> void: restore_all())


func _process(delta: float) -> void:
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if power < max_power():
		power = minf(power + power_regen * delta, max_power())
		changed.emit()


func max_power() -> int:
	return BASE_MAX_POWER + Grimoire.witch_strength() / STRENGTH_PER_POWER


## Gibt false zurück, wenn die Hexenkraft nicht reicht.
func spend_power(amount: float) -> bool:
	if power < amount:
		return false
	power -= amount
	changed.emit()
	return true


func restore_power(amount: float) -> void:
	power = minf(power + amount, max_power())
	changed.emit()


## Heiltrank: Leben zurück, höchstens bis zum Maximum.
func heal(amount: int) -> void:
	if health <= 0:
		return
	health = mini(health + amount, max_health)
	changed.emit()
	healed.emit(amount)


func make_invulnerable(seconds: float) -> void:
	_invulnerable = maxf(_invulnerable, seconds)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


## Gibt false zurück, wenn der Treffer nicht zählte (unverwundbar).
## source sagt, woher er kam ("sun" …); Main entscheidet danach, wie eine
## Niederlage ausgeht.
func take_damage(amount: int, source: String = "") -> bool:
	if health <= 0 or is_invulnerable():
		return false
	last_damage_source = source
	health = maxi(health - amount, 0)
	changed.emit()
	damaged.emit(amount, source)
	if health == 0:
		died.emit()
	return true


func restore_all() -> void:
	health = max_health
	power = max_power()
	changed.emit()


func is_full() -> bool:
	return health >= max_health and power >= max_power()
