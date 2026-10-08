extends Node2D

## Ein Glühwürmchen: schwebt langsam um seinen Platz, blinkt und ist nur
## nachts zu sehen. Reine Atmosphäre. Siehe docs/ASSETS.md, Glühwürmchen.

const TEXTURE := preload("res://assets/environment/fauna/firefly.png")
const FRAME_COUNT := 6

# Wie weit es sich von seinem Platz entfernt (Pixel).
@export var wander: Vector2 = Vector2(14, 9)
# Wie schnell es schwebt. Jedes bekommt eine leicht andere Geschwindigkeit.
@export var speed: float = 0.6

var _home := Vector2.ZERO
var _time := 0.0
var _phase := Vector2.ZERO
var _tempo := 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: NightLight = $Light


func _ready() -> void:
	_home = position
	_time = randf() * 100.0
	_phase = Vector2(randf() * TAU, randf() * TAU)
	_tempo = randf_range(0.7, 1.3)
	sprite.sprite_frames = Decor.strip_frames(TEXTURE, FRAME_COUNT, 6.0 * _tempo)
	sprite.frame = randi() % FRAME_COUNT
	sprite.play()


func _process(delta: float) -> void:
	_time += delta * speed * _tempo
	# Zwei überlagerte Sinuswellen je Achse: wirkt ziellos statt kreisförmig.
	var drift := Vector2(
		sin(_time * 1.3 + _phase.x) + 0.5 * sin(_time * 2.9 + _phase.y),
		sin(_time * 1.1 + _phase.y) + 0.5 * sin(_time * 2.3 + _phase.x)) / 1.5
	position = (_home + drift * wander).round()
	# Tagsüber unsichtbar, in der Dämmerung blenden sie sanft ein.
	modulate.a = DayCycle.night_factor()
	visible = modulate.a > 0.01
