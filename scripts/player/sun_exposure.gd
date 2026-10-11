class_name SunExposure
extends Node

## Die Hexe ist ein Nachtwesen: Ab Sonnenaufgang (6:00) brennt die Sonne sie,
## solange sie draußen ist. Von vollem Leben aus bricht sie gegen 8 Uhr
## zusammen und wacht spät am Abend im Bett auf (siehe main.gd). Im
## Unterschlupf (Level.indoors) ist sie sicher. Um 5 Uhr warnt DayCycle vor.
## Entscheidung: 11.10.2026, docs/QUALITY_OVERHAUL.md.
##
## Eigener Node unter dem Player (wie PlayerSounds), damit player.gd klein bleibt.

# Alle so viele Spielminuten ein Punkt Schaden. Bei 10 Leben: 6:00 + 10 × 12
# Minuten = 8:00. Wer schon verletzt ist (Kampf), hat entsprechend weniger Zeit.
const MINUTES_PER_DAMAGE := 12.0
# Kurzes warmes Aufglühen der Hexe bei jedem Sonnentreffer (Kerzenlicht).
const FLASH_COLOR := Color(1.6, 1.15, 0.7)
const FLASH_TIME := 0.35

# Gesammelte Spielminuten in der Sonne seit dem letzten Schaden.
var _burn := 0.0
var _last_minutes := 0.0
# Die Meldung "Die Sonne brennt" nur einmal pro Morgen.
var _warned_today := false

@onready var player: Player = get_parent()
@onready var vitals: Vitals = player.get_node("Vitals")


func _ready() -> void:
	_last_minutes = DayCycle.minutes


func _process(_delta: float) -> void:
	# Vergangene Spielminuten seit dem letzten Frame. Große Sprünge (Schlafen,
	# Spielstand laden) zählen nicht.
	var elapsed := fposmod(DayCycle.minutes - _last_minutes, DayCycle.MINUTES_PER_DAY)
	_last_minutes = DayCycle.minutes
	if elapsed > 30.0:
		elapsed = 0.0
	if not DayCycle.is_daytime():
		_burn = 0.0
		_warned_today = false
		return
	if not _is_exposed():
		return
	_burn += elapsed
	while _burn >= MINUTES_PER_DAMAGE:
		if not vitals.take_damage(1, "sun"):
			# Gerade unverwundbar (Dash): im nächsten Frame noch einmal.
			break
		_burn -= MINUTES_PER_DAMAGE
		_flash()
		if not _warned_today:
			_warned_today = true
			Messages.deny(tr("MSG_SUN_BURNS"))


## Draußen und unterwegs? Beim Schlafen oder Ortswechsel (Steuerung aus)
## brennt nichts.
func _is_exposed() -> bool:
	if not player.is_physics_processing():
		return false
	var level := get_tree().get_first_node_in_group("level") as Level
	return level != null and not level.indoors


func _flash() -> void:
	var sprite := player.animated_sprite
	sprite.modulate = FLASH_COLOR
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, FLASH_TIME)
