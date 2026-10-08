extends Node2D

## Eine Motte, die nachts um eine Lichtquelle kreist (Lagerfeuer, Laterne,
## Glutpilz). Der Node steht in der Lichtmitte, die Motte kreist darum.
## Reine Atmosphäre. Siehe docs/ASSETS.md, Ambient-Fauna.

const TEXTURES := [
	preload("res://assets/environment/fauna/moth.png"),
	preload("res://assets/environment/fauna/moth_dark.png"),
]

# Halbachsen der Kreisbahn in Pixeln (flach, wie von schräg oben gesehen).
@export var radius: Vector2 = Vector2(10, 6)
# Umläufe pro Sekunde, ungefähr.
@export var speed: float = 0.5

var _angle := 0.0
var _tempo := 1.0
var _time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Zwei Farbvarianten mischen, zufällige Richtung und Phase.
	sprite.sprite_frames = Decor.strip_frames(TEXTURES.pick_random(), 4, 12.0)
	sprite.frame = randi() % 4
	sprite.play()
	_angle = randf() * TAU
	_tempo = randf_range(0.8, 1.25) * (1.0 if randf() < 0.5 else -1.0)


func _process(delta: float) -> void:
	_time += delta
	_angle += delta * speed * TAU * _tempo
	# Leicht unregelmäßig: Der Radius atmet, und ab und zu ein kleiner Schlenker.
	var wobble := 1.0 + 0.25 * sin(_time * 1.7) + 0.15 * sin(_time * 4.3)
	sprite.position = (Vector2(cos(_angle), sin(_angle)) * radius * wobble).round()
	modulate.a = DayCycle.night_factor()
	visible = modulate.a > 0.01
