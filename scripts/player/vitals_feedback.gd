class_name VitalsFeedback
extends Node

## Zeigt, was mit dem Leben der Hexe passiert, ohne dass man auf die Leiste
## schauen muss:
## - Treffer: Sie blitzt kurz bordeauxrot-hell auf, das Bild wackelt leicht,
##   und solange sie danach unverwundbar ist, blinkt sie.
## - Heilen: rote Funken steigen auf.
## Sonnenschaden hat sein eigenes warmes Aufglühen (SunExposure).
## Eigener Node unter dem Player, damit player.gd klein bleibt.

const HIT_COLOR := Color(2.0, 0.9, 1.1)
const HIT_FLASH := 0.18
# Wackeln: höchstens so viele Pixel, so lange. Ganzzahlig, damit das Bild
# pixelscharf bleibt.
const SHAKE_PIXELS := 2
const SHAKE_TIME := 0.18
# Blinken nach einem Treffer: so lange sichtbar, so lange halb durchsichtig.
const BLINK_PERIOD := 0.12
const BLINK_ALPHA := 0.35
const HEAL_COLOR := Color("#D4475E")

var _shake_left := 0.0
var _blinking := false
var _blink_time := 0.0

@onready var player: Player = get_parent()
@onready var vitals: Vitals = player.get_node("Vitals")


func _ready() -> void:
	vitals.damaged.connect(_on_damaged)
	vitals.healed.connect(_on_healed)


func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		player.camera.offset = Vector2(randi_range(-SHAKE_PIXELS, SHAKE_PIXELS), randi_range(-SHAKE_PIXELS, SHAKE_PIXELS)) if _shake_left > 0.0 else Vector2.ZERO
	if _blinking:
		_blink_time += delta
		# Blinkt, solange die Unverwundbarkeit nach dem Treffer läuft.
		if not vitals.is_invulnerable():
			_blinking = false
			player.animated_sprite.self_modulate.a = 1.0
		else:
			player.animated_sprite.self_modulate.a = BLINK_ALPHA if fmod(_blink_time, BLINK_PERIOD) > BLINK_PERIOD * 0.6 else 1.0


func _on_damaged(_amount: int, source: String) -> void:
	if source == "sun":
		return
	var sprite := player.animated_sprite
	sprite.modulate = HIT_COLOR
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, HIT_FLASH)
	_shake_left = SHAKE_TIME
	_blinking = true
	_blink_time = 0.0
	Sfx.play("combat/hurt")


func _on_healed(_amount: int) -> void:
	CombatFx.sparks(player.get_parent(), player.global_position + Vector2(0, -24), HEAL_COLOR, 14, 25.0, -30.0)
