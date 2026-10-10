class_name BlightBeetle
extends CharacterBody2D

## Ein Käfer, den die Bitterblüte befallen hat. Er krabbelt um seinen Platz,
## bemerkt die Hexe, hält kurz inne und rammt sie dann mit Anlauf. Danach
## braucht er einen Moment: die Gelegenheit, zurückzuschlagen.
## Reinigen statt töten: Bei null Leben fällt die Blüte ab, der geheilte
## Käfer krabbelt davon und lässt ein Bitterblütenblatt zurück.
## Wo Käfer leben und wann neue kommen, regelt WildGrowth (wie bei Pilzen).
## Design: docs/design/game_design.md, Abschnitt 7.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)

## Kommt, wenn er gereinigt ist. WildGrowth trägt das in Wilds ein.
signal collected

enum State { WANDER, NOTICE, CHARGE, RECOVER, STAGGER, CLEANSED }

const ENEMY_LAYER := 4
const WORLD_LAYER := 1
const DROP_ITEM := "bitterbloom_petal"
const SHADOW := preload("res://assets/effects/shadows/shadow_22x6.png")

@export var max_health: int = 4
@export var wander_speed: float = 22.0
@export var wander_radius: float = 50.0
@export var notice_distance: float = 110.0
@export var give_up_distance: float = 190.0
@export var charge_speed: float = 150.0
@export var charge_time: float = 0.6
@export var notice_time: float = 0.45
@export var recover_time: float = 0.8
@export var contact_damage: int = 1

var health := 4
var state := State.WANDER

var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _timer := 0.0
var _charge_direction := Vector2.ZERO
var _knockback := Vector2.ZERO
var _flash := 0.0
var _walk_time := 0.0
var _player: Player
var _glow: Glow
var _light: NightLight


func _ready() -> void:
	health = max_health
	_home = position
	_target = _home
	add_to_group("blighted")
	collision_layer = ENEMY_LAYER
	collision_mask = WORLD_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)
	# Trefferzone für Zauber: so groß wie der sichtbare Panzer. Die Körperform
	# oben ist nur ein flacher Streifen an den Füßen (fürs Laufen), Zauber auf
	# Panzerhöhe würden darüber hinwegfliegen.
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = ENEMY_LAYER
	hitbox.collision_mask = 0
	var hitbox_shape := CollisionShape2D.new()
	var hitbox_rect := RectangleShape2D.new()
	hitbox_rect.size = Vector2(16, 18)
	hitbox_shape.shape = hitbox_rect
	hitbox_shape.position = Vector2(0, -9)
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)
	# Berührung tut der Hexe weh.
	var hurt := Area2D.new()
	hurt.collision_layer = 0
	hurt.collision_mask = WORLD_LAYER
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(18, 12)
	hurt_shape.shape = hurt_rect
	hurt_shape.position = Vector2(0, -5)
	hurt.add_child(hurt_shape)
	hurt.body_entered.connect(_on_touch)
	add_child(hurt)
	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.position = Vector2(1, 1)
	shadow.modulate.a = 0.5
	shadow.z_index = -5
	add_child(shadow)
	_glow = Glow.new()
	_glow.beetle = self
	add_child(_glow)
	# Ein schwaches Magenta-Licht, damit der Befall nachts sichtbar ist.
	_light = NightLight.new()
	_light.texture = preload("res://assets/effects/lights/light_round_32.png")
	_light.color = Color("#C2307A")
	_light.base_energy = 0.6
	_light.position = Vector2(0, -10)
	add_child(_light)
	_pick_wander_target()


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_timer -= delta
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	var to_player := _player.global_position - global_position if _player else Vector2.INF
	match state:
		State.WANDER:
			velocity = (_target - position).limit_length(wander_speed)
			if position.distance_to(_target) < 3.0 or _timer <= 0.0:
				_pick_wander_target()
			if to_player.length() < notice_distance:
				_set_state(State.NOTICE, notice_time)
		State.NOTICE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_charge_direction = to_player.normalized()
				_set_state(State.CHARGE, charge_time)
		State.CHARGE:
			velocity = _charge_direction * charge_speed
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_set_state(State.RECOVER, recover_time)
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				if to_player.length() < give_up_distance:
					_set_state(State.NOTICE, notice_time)
				else:
					_set_state(State.WANDER, 3.0)
		State.STAGGER:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				_set_state(State.RECOVER, recover_time * 0.5)
		State.CLEANSED:
			# Geheilt davonkrabbeln, weg von der Hexe.
			velocity = -to_player.normalized() * 70.0 if _player else Vector2.ZERO
			modulate.a = clampf(_timer, 0.0, 1.0)
			if _timer <= 0.0:
				queue_free()
	move_and_slide()
	if velocity.length() > 1.0:
		_walk_time += delta
	queue_redraw()
	_glow.queue_redraw()


func _set_state(new_state: State, seconds: float) -> void:
	state = new_state
	_timer = seconds


func _pick_wander_target() -> void:
	_target = _home + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * wander_radius
	_timer = 3.0


## Von einem Zauber getroffen (Spell ruft das auf).
func take_hit(damage: int, knockback: Vector2) -> void:
	if state == State.CLEANSED:
		return
	health -= damage
	_flash = 0.12
	if health <= 0:
		_cleanse()
		return
	_knockback = knockback * 2.0
	_set_state(State.STAGGER, 0.2)


func _on_touch(body: Node2D) -> void:
	if state == State.CLEANSED or not body is Player:
		return
	var witch := body as Player
	var vitals: Vitals = witch.get_node("Vitals")
	if vitals.take_damage(contact_damage):
		vitals.make_invulnerable(0.8)
		witch.start_dash((witch.global_position - global_position).normalized() * 220.0, 0.12)
		# Wer angegriffen wird, zieht Digitalis.
		(witch.get_node("Combat") as Combat).set_active(true)
	if state == State.CHARGE:
		_set_state(State.RECOVER, recover_time)


## Reinigen statt töten: Die Blüte fällt ab, ein Blatt bleibt liegen.
func _cleanse() -> void:
	_set_state(State.CLEANSED, 1.6)
	collision_layer = 0
	# Gereinigte Käfer fangen keine Zauber mehr ab.
	$Hitbox.set_deferred("collision_layer", 0)
	_light.enabled = false
	remove_from_group("blighted")
	var petals := CPUParticles2D.new()
	petals.one_shot = true
	petals.explosiveness = 0.9
	petals.amount = 18
	petals.lifetime = 1.0
	petals.spread = 180.0
	petals.gravity = Vector2(0, 60)
	petals.initial_velocity_min = 20.0
	petals.initial_velocity_max = 55.0
	petals.color_ramp = _petal_colors()
	get_parent().add_child(petals)
	petals.global_position = global_position + Vector2(0, -6)
	petals.emitting = true
	petals.finished.connect(petals.queue_free)
	var drop := DroppedItem.new()
	drop.item_id = DROP_ITEM
	get_parent().add_child(drop)
	drop.global_position = global_position
	Grimoire.report("cleanse", {"id": "blight_beetle"})
	collected.emit()


func _petal_colors() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color("#C2307A"))
	gradient.set_color(1, Color("#2B1633"))
	return gradient


## Ein Käfer von oben, etwa kniehoch zur Hexe: dunkler Panzer, darauf die
## Bitterblüte. Blüte und Augen glimmen magenta (eigene, unbeleuchtete
## Ebene), damit man ihn auch nachts sofort sieht. Gereinigt: grüner Panzer
## ohne Blüte.
func _draw() -> void:
	var cleansed := state == State.CLEANSED
	var shell := Color("#30624A") if cleansed else Color("#3A1840")
	var shell_light := Color("#62A06E") if cleansed else Color("#6E2A5E")
	var outline := Color("#0E0A14")
	var step := 1.0 if fmod(_walk_time * 10.0, 2.0) < 1.0 else -1.0
	# Beine, drei je Seite, wackeln beim Laufen gegeneinander.
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var y := -12.0 + i * 4.0 + step * side * (1 if i % 2 == 0 else -1)
			draw_rect(Rect2(side * 9.0 - (2.0 if side < 0 else 0.0), y, 3, 1), outline)
	# Panzer mit Kontur, Licht von oben links, Naht in der Mitte.
	draw_rect(Rect2(-8, -15, 16, 13), outline)
	draw_rect(Rect2(-7, -16, 14, 15), outline)
	draw_rect(Rect2(-7, -15, 14, 13), shell)
	draw_rect(Rect2(-6, -15, 4, 10), shell_light)
	draw_rect(Rect2(0, -15, 1, 13), outline)
	# Kopf.
	draw_rect(Rect2(-4, -19, 8, 4), outline)
	draw_rect(Rect2(-3, -18, 6, 2), shell)
	if _flash > 0.0:
		draw_rect(Rect2(-8, -19, 16, 18), Color(1, 1, 1, 0.75))



## Blüte und Augen leuchten durch die Nacht (unbeleuchtete Ebene).
class Glow:
	extends Node2D

	var beetle: BlightBeetle

	func _ready() -> void:
		var unshaded := CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = unshaded

	func _draw() -> void:
		var cleansed := beetle.state == State.CLEANSED
		var eye := Color("#EADFCB") if cleansed else Color("#E458B1")
		draw_rect(Rect2(-3, -18, 1, 1), eye)
		draw_rect(Rect2(2, -18, 1, 1), eye)
		if cleansed:
			return
		# Die Bitterblüte: vier Blätter, goldene Mitte.
		draw_rect(Rect2(-3, -11, 6, 4), Color("#C2307A"))
		draw_rect(Rect2(-2, -13, 4, 8), Color("#C2307A"))
		draw_rect(Rect2(-2, -12, 2, 2), Color("#E458B1"))
		draw_rect(Rect2(-1, -10, 2, 2), Color("#D9A441"))
		if beetle.state == State.NOTICE:
			# Ausrufezeichen: gleich greift er an.
			draw_rect(Rect2(-1, -30, 2, 6), Color("#E458B1"))
			draw_rect(Rect2(-1, -23, 2, 2), Color("#E458B1"))
