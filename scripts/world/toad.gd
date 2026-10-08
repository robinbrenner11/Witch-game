extends Node2D

## Kröte im Garten: sitzt, atmet, quakt manchmal und hüpft ein Stück weg,
## wenn die Hexe zu nah kommt. Sie bleibt in der Nähe ihres Platzes.
## Reine Atmosphäre. Frames: docs/ASSETS.md, Ambient-Fauna.

const TEXTURE := preload("res://assets/environment/fauna/toad.png")
const FRAME_SIZE := Vector2i(16, 16)
# Name -> [Frames, FPS, Loop]
const ANIMATIONS := {
	"idle": [[0, 1], 2.0, true],
	"croak": [[0, 2, 2, 0], 4.0, false],
	"hop": [[3, 4, 5, 6, 7], 10.0, false],
}
# In welchen Frames von "hop" sie in der Luft ist und sich bewegt.
const AIRBORNE_FRAMES := [1, 2, 3]

# Ab dieser Entfernung zur Hexe hüpft sie weg.
@export var shy_distance: float = 40.0
# Wie weit ein Sprung geht.
@export var hop_length: float = 9.0
# Weiter als so weit entfernt sie sich nicht von ihrem Platz.
@export var home_radius: float = 48.0
# Pause zwischen zwei Quakern (Sekunden).
@export var croak_wait: Vector2 = Vector2(4, 12)

var _home := Vector2.ZERO
var _hop_direction := Vector2.ZERO
var _busy := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_home = position
	sprite.sprite_frames = _build_frames()
	sprite.offset = Vector2(0, -FRAME_SIZE.y / 2.0)
	sprite.play("idle")
	sprite.frame_changed.connect(_on_frame_changed)
	_croak_loop()


func _physics_process(_delta: float) -> void:
	if _busy:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) < shy_distance:
		_hop_away_from(player.global_position)


func _hop_away_from(danger: Vector2) -> void:
	var away := (global_position - danger).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	# Etwas zufällig, und nie zu weit weg von zu Hause: dann lieber dorthin.
	away = away.rotated(randf_range(-0.6, 0.6))
	if (position + away * hop_length).distance_to(_home) > home_radius:
		away = (_home - position).normalized().rotated(randf_range(-0.8, 0.8))
	_hop_direction = away
	await _play("hop")


func _on_frame_changed() -> void:
	if sprite.animation == "hop" and sprite.frame in AIRBORNE_FRAMES:
		position += _hop_direction * hop_length / AIRBORNE_FRAMES.size()
		position = position.round()


func _croak_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(croak_wait.x, croak_wait.y), false).timeout
		if is_inside_tree() and not _busy:
			await _play("croak")


func _play(animation: String) -> void:
	_busy = true
	sprite.play(animation)
	await sprite.animation_finished
	sprite.play("idle")
	_busy = false


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation: String in ANIMATIONS:
		var spec: Array = ANIMATIONS[animation]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, spec[1])
		frames.set_animation_loop(animation, spec[2])
		for index: int in spec[0]:
			var atlas := AtlasTexture.new()
			atlas.atlas = TEXTURE
			atlas.region = Rect2(Vector2(index * FRAME_SIZE.x, 0), FRAME_SIZE)
			frames.add_frame(animation, atlas)
	return frames
