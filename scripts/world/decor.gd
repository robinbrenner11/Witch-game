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
# Flache Deko (Hexenring, Teppich) liegt wie die Beete auf dem Boden.
const FLAT_Z := -6
const SHADOW_ALPHA := 0.5
const LIGHT_TEXTURE := preload("res://assets/effects/lights/light_round_64.png")
const FADED_ALPHA := 0.45
# Wie schnell das Durchsichtig-Werden geht (Alpha pro Sekunde).
const FADE_SPEED := 4.0
# Sammelbares raschelt kurz, wenn die Hexe so nah herankommt (Pixel).
const RUSTLE_DISTANCE := 56.0

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
# Liegt flach auf dem Boden: immer unter der Hexe, auch wenn sie mitten
# darin steht (Hexenring). Sonst gilt die Y-Sortierung.
@export var flat: bool = false
# Hängt von oben (Glas am Balken): Der Ursprung ist dann der Aufhängepunkt
# oben Mitte statt des Fußpunkts.
@export var hang: bool = false
# Große Objekte (Bäume): Steht die Hexe dahinter, wird das Bild halb
# durchsichtig, damit man sie und was dort liegt noch sieht.
@export var fade_when_behind: bool = false
# Fester Frame, z. B. Truhe zu (0) statt offen (1). -1 = zufällig.
# Mit fps = 0 bleibt das Bild stehen.
@export var start_frame: int = -1

@export_group("Light")
# 0 = kein Licht.
@export var light_energy: float = 0.0
@export var light_color: Color = Color.WHITE
@export var light_radius: float = 40.0
# Lichtmitte relativ zum Fußpunkt.
@export var light_offset: Vector2 = Vector2.ZERO
@export var light_flicker: float = 0.0
# Bei Vollmond leuchtet das Licht so viel stärker (Hexenring). 1 = gleich.
@export var full_moon_boost: float = 1.0

# Sammelbares (Weed, Forage) setzt das selbst: Es wackelt kurz, wenn die
# Hexe in die Nähe kommt. So erkennt man es, ohne dass etwas leuchtet.
var rustle_when_near := false
var sprite: AnimatedSprite2D
var glow_sprite: AnimatedSprite2D
var _player_was_near := false


func _ready() -> void:
	if texture == null:
		return
	_add_shadow()
	sprite = _add_sprite(texture, false)
	if glow_texture:
		glow_sprite = _add_sprite(glow_texture, true)
	_add_collision()
	_add_light()
	set_process((fade_when_behind or rustle_when_near) and not Engine.is_editor_hint())


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if fade_when_behind:
		_update_fade(player, delta)
	if rustle_when_near:
		var near := player.global_position.distance_to(global_position) < RUSTLE_DISTANCE
		if near and not _player_was_near:
			rustle()
		_player_was_near = near


## Kurzes Wackeln um ein Pixel hin und her, wie ein Tier im Gebüsch.
func rustle() -> void:
	var tween := create_tween()
	for x in [1.0, -1.0, 1.0, -1.0, 0.0]:
		tween.tween_callback(_shift_sprites.bind(x))
		tween.tween_interval(0.07)


func _shift_sprites(x: float) -> void:
	sprite.position.x = x
	if glow_sprite:
		glow_sprite.position.x = x


func _update_fade(player: Node2D, delta: float) -> void:
	var target := 1.0
	if player.global_position.y < global_position.y:
		# Die Körpermitte der Hexe, nicht ihre Füße: Sie zählt als verdeckt,
		# sobald die Krone über ihr liegt.
		if cover_rect().has_point(player.global_position + Vector2(0, -24)):
			target = FADED_ALPHA
	var alpha := move_toward(sprite.modulate.a, target, FADE_SPEED * delta)
	sprite.modulate.a = alpha
	if glow_sprite:
		glow_sprite.modulate.a = alpha


## Die Fläche, die das Bild in der Welt bedeckt (ohne die Fußzeile).
func cover_rect() -> Rect2:
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	return Rect2(global_position - Vector2(size.x / 2.0, size.y), size - Vector2(0, 8))


func _add_sprite(strip: Texture2D, unshaded: bool) -> AnimatedSprite2D:
	var animated := AnimatedSprite2D.new()
	animated.sprite_frames = strip_frames(strip, frame_count, fps)
	var height := strip.get_height()
	animated.offset = Vector2(0, height / 2.0 if hang else -height / 2.0)
	animated.flip_h = flip
	if flat:
		animated.z_index = FLAT_Z
	if unshaded:
		var material := CanvasItemMaterial.new()
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		animated.material = material
	add_child(animated)
	if frame_count > 1:
		# Zufälliger Startframe, sonst wiegen alle Bäume im Gleichtakt. Die
		# Leucht-Ebene übernimmt den Frame des Bildes, sonst läuft sie daneben her.
		if sprite:
			animated.frame = sprite.frame
		elif start_frame >= 0:
			animated.frame = start_frame
		else:
			animated.frame = randi() % frame_count
		if fps > 0.0:
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
	if full_moon_boost != 1.0:
		var update := func(_phase: int = 0) -> void:
			light.base_energy = light_energy * (full_moon_boost if Moon.is_full() else 1.0)
		update.call()
		Moon.phase_changed.connect(update)


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
