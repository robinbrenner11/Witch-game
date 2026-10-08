extends Node2D

## Die Eule auf dem toten Baum im Wald. Sitzt still, blinzelt, schaut sich um
## und plustert sich manchmal auf. Nachts sieht man fast nur ihre Augen.
## Reine Atmosphäre. Frames und Abläufe: docs/ASSETS.md, Ambient-Fauna.
## Später wird sie eine Person (Grimoire-Hinweise, game_design.md).

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

# Wie hoch über dem Node sie sitzt. Der Node selbst steht knapp vor dem
# Baumfuß, damit die Y-Sortierung sie vor ihren Baum zeichnet und nicht
# dahinter (dort, wo sie sitzt, wäre sie sonst hinter dem Stamm).
@export var perch_height: float = 70.0
# Pause zwischen zwei Bewegungen (Sekunden).
@export var min_pause: float = 2.0
@export var max_pause: float = 6.0

var _sprites: Array[AnimatedSprite2D] = []


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
	_idle_loop()


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
