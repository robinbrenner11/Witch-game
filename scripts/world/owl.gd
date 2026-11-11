extends Node2D

## Die Eule auf dem toten Baum im Wald. Sitzt still, blinzelt, schaut sich um
## und plustert sich manchmal auf. Nachts sieht man fast nur ihre Augen.
## Kommt die Hexe zu nah an ihren Baum, fliegt sie auf und davon; ist die
## Hexe wieder ein Stück weg, sitzt sie nach einer Weile wieder auf dem Ast.
## Reine Atmosphäre. Frames und Abläufe: docs/ASSETS.md, Ambient-Fauna.
## Später wird sie eine Person (Grimoire-Hinweise, game_design.md), deshalb
## verschwindet sie nie für immer.

const TEXTURE := preload("res://assets/environment/fauna/owl.png")
const GLOW_TEXTURE := preload("res://assets/environment/fauna/owl_glow.png")
const FRAME_SIZE := Vector2i(16, 18)

# Name -> Frame-Folge. Alle laufen einmal und kehren dann zu "idle" zurück.
const ACTIONS := {
	"blink": [0, 1, 0],
	"look_left": [2, 2, 2, 2, 2, 2, 0],
	"look_right": [3, 3, 3, 3, 3, 3, 0],
	"ruffle": [0, 4, 4, 0],
}
const ACTION_FPS := 6.0
const FLY_TEXTURE := preload("res://assets/environment/fauna/owl_fly.png")
const FLY_GLOW_TEXTURE := preload("res://assets/environment/fauna/owl_fly_glow.png")
const FLY_FRAME_SIZE := Vector2i(32, 20)
const FLY_FPS := 8.0
# So nah (Pixel zum Baumfuß) darf die Hexe kommen, bevor sie auffliegt.
const FLEE_DISTANCE := 56.0
# Wohin und wie lange sie fliegt (nach oben und zur Seite, dann weg).
const FLIGHT := Vector2(90, -70)
const FLIGHT_TIME := 1.6
# Zurück auf den Ast frühestens nach so vielen Sekunden und erst, wenn die
# Hexe mindestens so weit weg ist.
const RETURN_TIME := 20.0
const RETURN_DISTANCE := 140.0

enum Mood { PERCHED, FLYING, AWAY }

# Wie hoch über dem Node sie sitzt. Der Node selbst steht knapp vor dem
# Baumfuß, damit die Y-Sortierung sie vor ihren Baum zeichnet und nicht
# dahinter (dort, wo sie sitzt, wäre sie sonst hinter dem Stamm).
@export var perch_height: float = 70.0
# Pause zwischen zwei Bewegungen (Sekunden).
@export var min_pause: float = 2.0
@export var max_pause: float = 6.0

var _sprites: Array[AnimatedSprite2D] = []
var _fly_sprites: Array[AnimatedSprite2D] = []
var mood := Mood.PERCHED
var _away_time := 0.0


func _ready() -> void:
	for strip in [TEXTURE, GLOW_TEXTURE]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = _build_frames(strip)
		# Fußpunkt = Krallen unten Mitte.
		sprite.offset = Vector2(0, -FRAME_SIZE.y / 2.0 - perch_height)
		if strip == GLOW_TEXTURE:
			var material := CanvasItemMaterial.new()
			material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			sprite.material = material
		add_child(sprite)
		_sprites.append(sprite)
	for strip in [FLY_TEXTURE, FLY_GLOW_TEXTURE]:
		var flyer := AnimatedSprite2D.new()
		flyer.sprite_frames = _build_fly_frames(strip)
		flyer.offset = Vector2(0, -FLY_FRAME_SIZE.y / 2.0 - perch_height)
		flyer.visible = false
		if strip == FLY_GLOW_TEXTURE:
			flyer.material = _sprites[1].material
		add_child(flyer)
		_fly_sprites.append(flyer)
	_idle_loop()


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var distance := player.global_position.distance_to(global_position)
	match mood:
		Mood.PERCHED:
			if distance < FLEE_DISTANCE:
				fly_away()
		Mood.AWAY:
			_away_time += delta
			if _away_time >= RETURN_TIME and distance > RETURN_DISTANCE:
				_return_to_perch()


## Auffliegen: Abflug-Bild, dann Flügelschlag, schräg nach oben, ausblenden.
func fly_away() -> void:
	if mood != Mood.PERCHED:
		return
	mood = Mood.FLYING
	for sprite in _sprites:
		sprite.visible = false
	for flyer in _fly_sprites:
		flyer.position = Vector2.ZERO
		flyer.modulate.a = 1.0
		flyer.visible = true
		flyer.play("takeoff")
	await get_tree().create_timer(1.0 / FLY_FPS, false).timeout
	for flyer in _fly_sprites:
		flyer.play("fly")
		flyer.flip_h = FLIGHT.x < 0
	var tween := create_tween().set_parallel()
	for flyer in _fly_sprites:
		tween.tween_property(flyer, "position", FLIGHT, FLIGHT_TIME)
		tween.tween_property(flyer, "modulate:a", 0.0, FLIGHT_TIME * 0.5).set_delay(FLIGHT_TIME * 0.5)
	await tween.finished
	for flyer in _fly_sprites:
		flyer.visible = false
	mood = Mood.AWAY
	_away_time = 0.0


## Unbemerkt zurück: einfach wieder auf dem Ast, leise eingeblendet.
func _return_to_perch() -> void:
	mood = Mood.PERCHED
	for sprite in _sprites:
		sprite.modulate.a = 0.0
		sprite.visible = true
		sprite.play("idle")
		create_tween().tween_property(sprite, "modulate:a", 1.0, 1.0)


func _build_fly_frames(strip: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.rename_animation(&"default", &"takeoff")
	frames.add_frame(&"takeoff", _fly_frame(strip, 0))
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly", FLY_FPS)
	for index in [1, 2, 3]:
		frames.add_frame(&"fly", _fly_frame(strip, index))
	return frames


func _fly_frame(strip: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = strip
	atlas.region = Rect2(Vector2(index * FLY_FRAME_SIZE.x, 0), FLY_FRAME_SIZE)
	return atlas


func _build_frames(strip: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.rename_animation(&"default", &"idle")
	frames.add_frame(&"idle", _frame(strip, 0))
	for action: String in ACTIONS:
		frames.add_animation(action)
		frames.set_animation_loop(action, false)
		frames.set_animation_speed(action, ACTION_FPS)
		for index: int in ACTIONS[action]:
			frames.add_frame(action, _frame(strip, index))
	return frames


func _frame(strip: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = strip
	atlas.region = Rect2(Vector2(index * FRAME_SIZE.x, 0), FRAME_SIZE)
	return atlas


## Wartet eine zufällige Zeit, spielt eine zufällige Bewegung, von vorn.
## Blinzeln kommt am häufigsten, Aufplustern am seltensten.
func _idle_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(min_pause, max_pause), false).timeout
		if not is_inside_tree():
			return
		if mood != Mood.PERCHED:
			continue
		var roll := randf()
		var action := "blink"
		if roll > 0.9:
			action = "ruffle"
		elif roll > 0.7:
			action = "look_left"
		elif roll > 0.5:
			action = "look_right"
		for sprite in _sprites:
			sprite.play(action)
		await _sprites[0].animation_finished
		for sprite in _sprites:
			sprite.play("idle")
