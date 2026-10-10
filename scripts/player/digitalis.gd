class_name Digitalis
extends Node2D

## Digitalis, der Fingerhut-Stab, so wie die Hexe ihn im Kampf neben sich
## führt. Zeigt nur an: Combat entscheidet, wo er steht und wann er zaubert.
## Der Ursprung ist der Fuß des Stabs. Grafik und Maße: docs/ASSETS.md,
## Abschnitt Digitalis.

const IDLE := preload("res://assets/items/digitalis/digitalis_idle.png")
const IDLE_GLOW := preload("res://assets/items/digitalis/digitalis_idle_glow.png")
const ATTACK := preload("res://assets/items/digitalis/digitalis_attack.png")
const ATTACK_GLOW := preload("res://assets/items/digitalis/digitalis_attack_glow.png")
const LIGHT_TEXTURE := preload("res://assets/effects/lights/light_round_64.png")

const FRAME_COUNT := 4
const IDLE_FPS := 4.0
const ATTACK_FPS := 12.0
# Der Fuß liegt im Frame (24×60) zwischen Spalte 10 und 11 an der Unterkante.
# Ohne centered rückt dieser Versatz ihn genau auf den Ursprung.
const FRAME_OFFSET := Vector2(-11, -60)
# Die glimmende Knospe an der Spitze, relativ zum Fuß (nicht gespiegelt).
const TIP := Vector2(5, -50)
const LIGHT_COLOR := Color(0.89, 0.35, 0.69)
const LIGHT_RADIUS := 24.0
# Lichtstärke je Idle-Frame, passend zum Puls der Spitze (0-1-2-1).
const IDLE_ENERGY: Array[float] = [0.5, 0.58, 0.65, 0.58]
const ATTACK_ENERGY := 1.2

var _sprite: AnimatedSprite2D
var _glow: AnimatedSprite2D
var _light: NightLight


func _ready() -> void:
	_sprite = _add_layer(false)
	_glow = _add_layer(true)
	_light = NightLight.new()
	_light.texture = LIGHT_TEXTURE
	_light.texture_scale = LIGHT_RADIUS * 2.0 / LIGHT_TEXTURE.get_width()
	_light.color = LIGHT_COLOR
	_light.position = TIP
	add_child(_light)
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_play(&"idle")


## Blick nach links: Stab spiegeln, damit die Glocken nach vorne zeigen.
## Gespiegelt wird der ganze Node um den Fuß, so wandern Spitze und Licht mit.
func set_flipped(flipped: bool) -> void:
	scale.x = -1.0 if flipped else 1.0


## Die Spitze in Weltkoordinaten, dort starten die Zauber.
func tip_position() -> Vector2:
	return to_global(TIP)


## Ein Zauber: Die Traube glüht einmal auf, danach wieder Idle.
func attack() -> void:
	_play(&"attack")


func _play(animation: StringName) -> void:
	_sprite.play(animation)
	_glow.play(animation)
	# Beide Ebenen starten im selben Frame, sonst läuft das Leuchten daneben her.
	_glow.frame = _sprite.frame
	_on_frame_changed()


func _on_frame_changed() -> void:
	_glow.frame = _sprite.frame
	if _sprite.animation == &"attack":
		_light.base_energy = ATTACK_ENERGY
	else:
		_light.base_energy = IDLE_ENERGY[_sprite.frame]


func _on_animation_finished() -> void:
	if _sprite.animation == &"attack":
		_play(&"idle")


func _add_layer(glow: bool) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", IDLE_GLOW if glow else IDLE, IDLE_FPS, true)
	_add_strip(frames, &"attack", ATTACK_GLOW if glow else ATTACK, ATTACK_FPS, false)
	var animated := AnimatedSprite2D.new()
	animated.sprite_frames = frames
	animated.centered = false
	animated.offset = FRAME_OFFSET
	if glow:
		# Die Leucht-Ebene ignoriert die Nachtfärbung, wie bei Pilzen und Tränken.
		var material := CanvasItemMaterial.new()
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		animated.material = material
	add_child(animated)
	return animated


func _add_strip(frames: SpriteFrames, animation: StringName, strip: Texture2D, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	var frame_size := Vector2(strip.get_width() / float(FRAME_COUNT), strip.get_height())
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame(animation, atlas)
