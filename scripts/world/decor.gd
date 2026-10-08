@tool
class_name Decor
extends Node2D

## Ein Stück Umgebung ohne eigene Spiellogik: Baum, Busch, Blume, Stein,
## Pilz. Alles Nötige (Sprite, Leucht-Ebene, Kollision, Schatten, Licht)
## entsteht aus den Export-Werten, deshalb ist jede Objektart nur eine kleine
## Szene in scenes/world/decor/, die diese Werte setzt. Neue Deko braucht so
## keinen neuen Code.
##
## Der Ursprung ist der Fußpunkt (unten Mitte), wie bei der Hexe. So sortiert
## die Y-Sortierung sie richtig vor oder hinter Objekte.
##
## @tool: Das Script läuft auch im Editor, damit man die Deko beim Platzieren sieht.

# Schatten liegen unter allen Objekten, aber über Boden (-10) und Beeten (-6).
const SHADOW_Z := -5
const SHADOW_ALPHA := 0.5
const LIGHT_TEXTURE := preload("res://assets/effects/lights/light_round_64.png")

# Waagerechter Streifen mit frame_count gleich breiten Frames.
@export var texture: Texture2D
@export var frame_count: int = 1
@export var fps: float = 6.0
# Nur die selbstleuchtenden Pixel, gleiche Frames. Wird unbeleuchtet darüber
# gelegt, damit es nachts durch die Dunkelheit strahlt.
@export var glow_texture: Texture2D
# Kollision am Fuß. (0, 0) = man kann hindurchlaufen (Blumen, Gras).
@export var collision_size: Vector2 = Vector2.ZERO
@export var shadow_texture: Texture2D
# Versatz des Schattens zum Fußpunkt, leicht nach rechts unten (Licht von oben links).
@export var shadow_offset: Vector2 = Vector2.ZERO
# Gespiegelt aufstellen, damit gleiche Objekte nicht gestempelt wirken.
@export var flip: bool = false

@export_group("Light")
# 0 = kein Licht.
@export var light_energy: float = 0.0
@export var light_color: Color = Color.WHITE
@export var light_radius: float = 40.0
# Lichtmitte relativ zum Fußpunkt.
@export var light_offset: Vector2 = Vector2.ZERO
@export var light_flicker: float = 0.0

var sprite: AnimatedSprite2D


func _ready() -> void:
	if texture == null:
		return
	_add_shadow()
	sprite = _add_sprite(texture, false)
	if glow_texture:
		_add_sprite(glow_texture, true)
	_add_collision()
	_add_light()


func _add_sprite(strip: Texture2D, unshaded: bool) -> AnimatedSprite2D:
	var animated := AnimatedSprite2D.new()
	animated.sprite_frames = strip_frames(strip, frame_count, fps)
	var height := strip.get_height()
	animated.offset = Vector2(0, -height / 2.0)
	animated.flip_h = flip
	if unshaded:
		var material := CanvasItemMaterial.new()
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		animated.material = material
	add_child(animated)
	if frame_count > 1:
		# Zufälliger Startframe, sonst wiegen alle Bäume im Gleichtakt. Die
		# Leucht-Ebene übernimmt den Frame des Bildes, sonst läuft sie daneben her.
		animated.frame = sprite.frame if sprite else randi() % frame_count
		animated.play()
	return animated


func _add_shadow() -> void:
	if shadow_texture == null:
		return
	var shadow := Sprite2D.new()
	shadow.texture = shadow_texture
	shadow.position = shadow_offset * Vector2(-1 if flip else 1, 1)
	shadow.modulate.a = SHADOW_ALPHA
	shadow.z_index = SHADOW_Z
	add_child(shadow)


func _add_collision() -> void:
	if collision_size == Vector2.ZERO:
		return
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = collision_size
	shape.shape = rect
	shape.position = Vector2(0, -collision_size.y / 2.0)
	body.add_child(shape)
	add_child(body)


func _add_light() -> void:
	if light_energy <= 0.0 or Engine.is_editor_hint():
		return
	var light := NightLight.new()
	light.texture = LIGHT_TEXTURE
	light.texture_scale = light_radius * 2.0 / LIGHT_TEXTURE.get_width()
	light.color = light_color
	light.base_energy = light_energy
	light.flicker = light_flicker
	light.position = light_offset
	add_child(light)


## Baut SpriteFrames aus einem waagerechten Sprite-Streifen (Loop).
static func strip_frames(strip: Texture2D, count: int, speed: float, loop: bool = true) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", speed)
	frames.set_animation_loop(&"default", loop)
	var frame_size := Vector2(strip.get_width() / float(count), strip.get_height())
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame(&"default", atlas)
	return frames
