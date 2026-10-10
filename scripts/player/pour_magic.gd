class_name PourMagic
extends Node2D

## Zauber-Ausgießen: Die Hexe stößt die Hand vor, der Trank fliegt als Orb im
## Bogen zum Beet, platzt dort und regnet herab. Erst danach wirkt er.
## Eigener Node unter dem Player, damit player.gd klein bleibt.
## Grafiken und Maße: docs/ASSETS.md, "Effekt Zauber-Ausgießen".

const ORB_TEXTURE := preload("res://assets/effects/pour_orb.png")
const RAIN_TEXTURE := preload("res://assets/effects/pour_rain.png")
const SPARKS_TEXTURE := preload("res://assets/effects/pour_sparks.png")

# Wo der Orb losfliegt: an den Fingerspitzen in Frame 3 von "pour", relativ zu
# den Füßen der Hexe.
const ORB_START := {
	Vector2.DOWN: Vector2(10, -33),
	Vector2.UP: Vector2(10, -44),
	Vector2.RIGHT: Vector2(12, -37),
	Vector2.LEFT: Vector2(-13, -37),
}
const ORB_FLIGHT_TIME := 0.3
# Wie hoch der Bogen in der Mitte des Flugs ist.
const ORB_ARC_HEIGHT := 14.0
# Frame des Stoßes in "pour" (ab 0 gezählt).
const PUSH_FRAME := 2

const RAIN_FRAMES := 6
const RAIN_FPS := 10.0
# Bei 3×3-Tränken platzen die äußeren Felder bis zu 2 Frames später, damit es
# nicht wie ein Stempel wirkt.
const MAX_RAIN_DELAY := 2.0 / RAIN_FPS
# Der Regen liegt knapp unter der Pflanzenwurzel (Pflanze: Tile-Mitte + 5), so
# sortiert ihn die Y-Sortierung über die Pflanze, aber hinter eine Hexe davor.
const RAIN_ROOT := Vector2(0, 6)
# Damit sitzt das Bild wie in ASSETS.md: Tile-Mitte, Offset (0, -8).
const RAIN_OFFSET := Vector2(0, -14)
# Platzpunkt (16, 6) im 32×48-Frame, umgerechnet auf die Tile-Mitte.
const LANDING_POINT := Vector2(0, -26)
# Hexenschlamm gluckst zäh statt zu plätschern und wächst ohne Glitzern.
const SLUDGE_ID := "potion_sludge"

@onready var player: Player = get_parent()


## Gießt item auf das Beet in center aus. Wer das aufruft, hat schon geprüft,
## dass dort etwas wachsen kann (Garden.can_grow_area).
func pour(item: ItemData, center: Vector2i) -> void:
	# Sofort aus dem Inventar, damit derselbe Trank nicht doppelt wirkt.
	Inventory.remove(item.id)
	player.play_action("pour")
	await player.wait_for_action_frame(PUSH_FRAME)

	var level := get_tree().get_first_node_in_group("level") as Level
	var target := _tile_center(center)
	if level:
		_fly_orb(level, player.global_position + ORB_START[player.facing],
				target + LANDING_POINT, item.pour_color)
	# Gewartet wird über Timer statt über die Effekt-Nodes: Die Wirkung soll
	# auch dann eintreten, wenn der Ort währenddessen verschwindet.
	await get_tree().create_timer(ORB_FLIGHT_TIME, false).timeout
	var is_sludge := item.id == SLUDGE_ID
	Sfx.play_at("garden/pour_sludge" if is_sludge else "garden/pour", target)

	if level and is_instance_valid(level):
		var radius := item.pour_radius
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var offset := Vector2i(x, y)
				var delay := 0.0 if offset == Vector2i.ZERO else randf_range(0.0, MAX_RAIN_DELAY)
				_splash(level, _tile_center(center + offset), item.pour_color, delay)
	await get_tree().create_timer(RAIN_FRAMES / RAIN_FPS, false).timeout

	if Garden.grow_area(center, item.pour_radius, item.pour_stages) and not is_sludge:
		Sfx.play_at("garden/grow_magic", target)


func _tile_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0


## Der Orb wabbelt (2 Frames) und fliegt im Bogen von from nach to.
func _fly_orb(level: Level, from: Vector2, to: Vector2, color: Color) -> void:
	var orb := _make_animation(ORB_TEXTURE, 2, Vector2i(8, 8), 8.0, true)
	orb.modulate = color
	# Im Flug über allem, sonst verschwindet er hinter Pflanzen.
	orb.z_index = 5
	level.add_child(orb)
	orb.global_position = from
	orb.play()
	var tween := orb.create_tween()
	tween.tween_method(func(t: float) -> void:
		# Gerade Linie plus Parabel nach oben, auf ganze Pixel gerundet.
		var arc := Vector2(0, -ORB_ARC_HEIGHT * 4.0 * t * (1.0 - t))
		orb.global_position = (from.lerp(to, t) + arc).round(),
		0.0, 1.0, ORB_FLIGHT_TIME)
	tween.tween_callback(orb.queue_free)


## Regen in der Trankfarbe und Funken darüber (die bleiben magenta).
func _splash(level: Level, tile_center: Vector2, color: Color, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(level):
			return
	var rain := _make_animation(RAIN_TEXTURE, RAIN_FRAMES, Vector2i(32, 48), RAIN_FPS, false)
	rain.modulate = color
	# Die Funken sind kein Kind des Regens, sonst würden sie dessen Farbe
	# erben (modulate gilt auch für Kinder). Später hinzugefügt = darüber.
	var sparks := _make_animation(SPARKS_TEXTURE, RAIN_FRAMES, Vector2i(32, 48), RAIN_FPS, false)
	for sprite in [rain, sparks]:
		sprite.offset = RAIN_OFFSET
		level.objects.add_child(sprite)
		sprite.global_position = tile_center + RAIN_ROOT
		sprite.animation_finished.connect(sprite.queue_free)
		sprite.play()


## Baut ein AnimatedSprite2D aus einem waagerechten Sprite-Streifen.
func _make_animation(texture: Texture2D, frame_count: int, frame_size: Vector2i,
		fps: float, loop: bool) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", fps)
	frames.set_animation_loop(&"default", loop)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame(&"default", atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	# Leuchtet auch nachts, es ist Magie.
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = material
	return sprite
