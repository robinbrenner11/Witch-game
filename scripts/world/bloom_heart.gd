class_name BloomHeart
extends StaticBody2D

## Das erste Blütenherz (Boss der Turmruine, Ende Akt 1). Steht still in der
## Mitte der Ruine und pulsiert. Kommt die Hexe nah oder trifft es, erwacht
## es und greift mit Bodenangriffen an, die sich deutlich ankündigen
## (BloomHazard):
##   Phase 1  Sporenplatzer: Kreise unter und neben der Hexe.
##   Phase 2  dazu Dornenstrahlen aus dem Herz; beim Wechsel kommen zwei Käfer.
##   Phase 3  schneller, und drei Schildknospen kreisen ums Herz: Erst wenn sie
##            geplatzt sind, nimmt es wieder Schaden.
## Gereinigt: Der Nebel im Wald bleibt für immer weg, der Befall weicht, eine
## Schlüsselseite und Blütenknospen bleiben liegen.

signal awakened
signal cleansed

enum State { DORMANT, FIGHT, CLEANSED }

const CLEANSED_FLAG := "bloom_heart_1_cleansed"
const ENEMY_ID := "bloom_heart"
const KEY_PAGE := "page_journal_02"
const ENEMY_LAYER := 4
const WORLD_LAYER := 1
const TEXTURES := [
	preload("res://assets/environment/bloom_heart/bloom_heart_1.png"),
	preload("res://assets/environment/bloom_heart/bloom_heart_2.png"),
	preload("res://assets/environment/bloom_heart/bloom_heart_3.png"),
]
const CLEANSED_TEXTURE := preload("res://assets/environment/bloom_heart/bloom_heart_cleansed.png")
const BEETLE := preload("res://scenes/world/blight_beetle.tscn")
const PAGE := preload("res://scenes/world/loose_page.tscn")
# Mitte des Herzens über dem Fußpunkt (dort entspringen die Strahlen).
const CORE := Vector2(0, -24)
const BUD_ORBIT := 46.0
const BUD_SPEED := 1.4
const SHIELD_MESSAGE_WAIT := 2.5

@export var max_health: int = 36
@export var awaken_distance: float = 170.0
## Pause zwischen zwei Angriffen je Phase (Sekunden).
@export var attack_wait: Array[float] = [2.6, 2.2, 1.7]
## Warnzeit vor dem Schlag je Phase.
@export var warn_time: Array[float] = [1.1, 1.0, 0.85]

var state := State.DORMANT
var health := 36
var phase := 1
var _wait := 1.5
var _attack_count := 0
var _buds: Array[BloomBud] = []
var _bud_angle := 0.0
var _flash := 0.0
var _time := 0.0
var _shield_message_wait := 0.0
var _sprite: Sprite2D
var _light: PointLight2D
var _beat: AudioStreamPlayer2D
var _hitbox: Area2D


func _ready() -> void:
	health = max_health
	_build()
	if WorldState.has_flag(CLEANSED_FLAG):
		_show_cleansed(false)
		return
	add_to_group("blighted")


func _build() -> void:
	collision_layer = WORLD_LAYER | ENEMY_LAYER
	collision_mask = 0
	var body := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	body.shape = circle
	body.position = Vector2(0, -8)
	add_child(body)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURES[0]
	_sprite.offset = Vector2(0, -32)
	add_child(_sprite)
	_light = PointLight2D.new()
	_light.texture = preload("res://assets/effects/lights/light_round_128.png")
	_light.color = Color("#C2307A")
	_light.position = CORE
	_light.texture_scale = 1.6
	add_child(_light)
	_hitbox = Area2D.new()
	_hitbox.collision_layer = ENEMY_LAYER
	_hitbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 40)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	_hitbox.add_child(shape)
	add_child(_hitbox)
	_beat = Sfx.make_loop_player("combat/heart_beat_loop", -6.0, 420.0)
	add_child(_beat)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta, 0.0)
	_shield_message_wait = maxf(_shield_message_wait - delta, 0.0)
	if state == State.CLEANSED:
		return
	# Atmen: das Licht schwillt im Takt des Herzschlags (1,2 s).
	var beat := pow(maxf(sin(_time * TAU / 1.2), 0.0), 4.0)
	_light.energy = (0.6 if state == State.DORMANT else 0.9) + beat * 0.6
	var tint := Color(1.0 + beat * 0.25, 1.0, 1.0 + beat * 0.15)
	_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else tint
	match state:
		State.DORMANT:
			var player := _player()
			if player and player.global_position.distance_to(global_position) <= awaken_distance:
				awaken()
		State.FIGHT:
			_orbit_buds(delta)
			_wait -= delta
			if _wait <= 0.0:
				_attack()
				_wait = attack_wait[phase - 1]


func awaken() -> void:
	if state != State.DORMANT:
		return
	state = State.FIGHT
	_wait = 1.2
	Sfx.play_at("combat/heart_awaken", global_position)
	Messages.post(tr("MSG_HEART_AWAKENS"))
	var player := _player()
	if player:
		(player.get_node("Combat") as Combat).set_active(true)
	awakened.emit()


func is_shielded() -> bool:
	return not _buds.is_empty()


func take_hit(damage: int, _knockback: Vector2, _stagger: bool = true) -> void:
	if state == State.CLEANSED:
		return
	if state == State.DORMANT:
		awaken()
	if is_shielded():
		CombatFx.sparks(get_parent(), global_position + CORE, Color("#EADFCB"), 6, 30.0)
		if _shield_message_wait <= 0.0:
			_shield_message_wait = SHIELD_MESSAGE_WAIT
			Messages.deny(tr("MSG_HEART_SHIELDED"))
		return
	health -= damage
	_flash = 0.1
	Sfx.play_at("combat/hit", global_position)
	if health <= 0:
		_cleanse()
		return
	var new_phase := 1 if health > max_health * 2 / 3 else (2 if health > max_health / 3 else 3)
	if new_phase != phase:
		_enter_phase(new_phase)


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_sprite.texture = TEXTURES[phase - 1]
	Sfx.play_at("combat/heart_awaken", global_position, -6.0)
	CombatFx.sparks(get_parent(), global_position + CORE, Color("#C2307A"), 30, 80.0)
	if phase == 2:
		for offset in [Vector2(-110, 30), Vector2(110, 30)]:
			var beetle := BEETLE.instantiate() as Node2D
			get_parent().add_child(beetle)
			beetle.global_position = global_position + offset
	elif phase == 3:
		_spawn_buds()


func _spawn_buds() -> void:
	for i in 3:
		var bud := BloomBud.new()
		get_parent().add_child.call_deferred(bud)
		_buds.append(bud)
		bud.popped.connect(func() -> void: _buds.erase(bud))
	_orbit_buds(0.0)


func _orbit_buds(delta: float) -> void:
	_bud_angle += BUD_SPEED * delta
	for i in _buds.size():
		var angle := _bud_angle + TAU * i / maxf(_buds.size(), 1)
		_buds[i].position = position + Vector2(cos(angle), sin(angle) * 0.6) * BUD_ORBIT + Vector2(0, -6)


func _attack() -> void:
	var player := _player()
	if player == null:
		return
	_attack_count += 1
	var rays := phase >= 2 and (_attack_count % 2 == 0 or (phase == 3 and randf() < 0.4))
	if rays:
		_thorn_rays()
		if phase == 3:
			_spore(player.global_position)
	else:
		_spore(player.global_position)
		for i in (2 if phase == 1 else 3):
			var offset := Vector2.from_angle(randf() * TAU) * randf_range(40.0, 75.0)
			_spore(player.global_position + offset)


func _spore(at: Vector2) -> void:
	var hazard := BloomHazard.new()
	hazard.shape = BloomHazard.Shape.CIRCLE
	hazard.radius = 22.0
	hazard.warn_time = warn_time[phase - 1]
	get_parent().add_child(hazard)
	hazard.global_position = at
	Sfx.play_at("combat/beetle_warn", at, -8.0)


func _thorn_rays() -> void:
	var count := 6 if phase == 2 else 8
	var start := randf() * TAU
	for i in count:
		var hazard := BloomHazard.new()
		hazard.shape = BloomHazard.Shape.RAY
		hazard.direction = Vector2.from_angle(start + TAU * i / count)
		hazard.length = 240.0
		hazard.width = 16.0
		hazard.warn_time = warn_time[phase - 1] + 0.1
		get_parent().add_child(hazard)
		hazard.global_position = global_position + CORE
	Sfx.play_at("combat/beetle_warn", global_position)


func _cleanse() -> void:
	state = State.CLEANSED
	remove_from_group("blighted")
	for hazard in get_tree().get_nodes_in_group(BloomHazard.GROUP):
		hazard.queue_free()
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 0.85
	burst.amount = 70
	burst.lifetime = 1.8
	burst.spread = 180.0
	burst.gravity = Vector2(0, 30)
	burst.initial_velocity_min = 30.0
	burst.initial_velocity_max = 110.0
	var colors := Gradient.new()
	colors.set_color(0, Color("#C2307A"))
	colors.set_color(1, Color("#FFB566"))
	burst.color_ramp = colors
	get_parent().add_child(burst)
	burst.global_position = global_position + CORE
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	Sfx.play_at("combat/cleanse", global_position)
	Sfx.play_at("garden/grow_magic", global_position)
	WorldState.set_flag(CLEANSED_FLAG)
	Grimoire.report("cleanse", {"id": ENEMY_ID})
	Messages.post(tr("MSG_HEART_CLEANSED"))
	_show_cleansed(true)
	for i in 3:
		var drop := DroppedItem.new()
		drop.item_id = "bloom_bud"
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector2(-24 + 24 * i, 18)
	if not Grimoire.has_fragment(KEY_PAGE, 0):
		var page := PAGE.instantiate()
		page.page_id = KEY_PAGE
		get_parent().add_child(page)
		page.global_position = global_position + Vector2(0, 34)
	var player := _player()
	if player:
		(player.get_node("Combat") as Combat).set_active(false)
	cleansed.emit()


## Gereinigt: bleich und still, warmes Licht, kein Treffer mehr möglich.
func _show_cleansed(animated: bool) -> void:
	state = State.CLEANSED
	_sprite.texture = CLEANSED_TEXTURE
	_sprite.modulate = Color.WHITE
	_light.color = Color("#FFB566")
	_light.energy = 0.7
	_hitbox.collision_layer = 0
	collision_layer = WORLD_LAYER
	_beat.stop()
	if animated:
		_sprite.modulate = Color(3, 3, 3)
		create_tween().tween_property(_sprite, "modulate", Color.WHITE, 1.2)


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player
