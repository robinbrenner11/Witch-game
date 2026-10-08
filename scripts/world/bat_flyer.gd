extends Node

## Lässt nachts ab und zu eine Fledermaus quer durchs Bild flattern.
## Hängt als Node in einem Ort (Garten, Wald). Reine Atmosphäre.
## Siehe docs/ASSETS.md, Ambient-Fauna.

const TEXTURE := preload("res://assets/environment/fauna/bat.png")

# Wartezeit zwischen zwei Fledermäusen (Sekunden).
@export var min_wait: float = 30.0
@export var max_wait: float = 90.0
# Die erste kommt früher, damit man sie überhaupt einmal sieht.
@export var first_wait: Vector2 = Vector2(8, 25)
@export var speed: float = 95.0
# Wie stark sie auf und ab schlingert.
@export var wave_height: float = 10.0


func _ready() -> void:
	_loop()


func _loop() -> void:
	var wait := randf_range(first_wait.x, first_wait.y)
	while is_inside_tree():
		await get_tree().create_timer(wait, false).timeout
		wait = randf_range(min_wait, max_wait)
		if is_inside_tree() and DayCycle.night_factor() > 0.6:
			_fly()


func _fly() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var center := camera.get_screen_center_position()
	var from_left := randf() < 0.5
	var y := center.y + randf_range(-0.4, 0.15) * view.y
	var start := Vector2(center.x + (view.x / 2.0 + 20.0) * (-1.0 if from_left else 1.0), y)
	var distance := view.x + 40.0

	var bat := AnimatedSprite2D.new()
	bat.sprite_frames = Decor.strip_frames(TEXTURE, 4, 10.0)
	# Fliegt über allem, auch über den Baumkronen.
	bat.z_index = 4
	bat.global_position = start
	get_parent().add_child(bat)
	bat.play()
	var direction := 1.0 if from_left else -1.0
	var tween := bat.create_tween()
	tween.tween_method(func(t: float) -> void:
		var x := start.x + direction * distance * t
		var wave := sin(t * TAU * 2.5) * wave_height + sin(t * TAU * 6.0) * 2.0
		bat.global_position = Vector2(x, start.y + wave).round(),
		0.0, 1.0, distance / speed)
	tween.tween_callback(bat.queue_free)
