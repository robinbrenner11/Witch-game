class_name BloomHeart
extends StaticBody2D

## Ein Blütenherz: der Boss eines befallenen Gebiets. Es wurzelt fest an
## seinem Platz und wehrt sich in drei Phasen, jede mit eigenem, gut
## lesbarem Telegraph (docs/COMBAT_SYSTEM.md, Blütenherz):
##   1 Wurzelstöße   Ringe am Boden füllen sich, dann brechen Wurzeln hervor.
##   2 Knospenpanzer Das Herz schließt sich und ruft Käfer. Solange sie leben,
##                   nimmt es keinen Schaden. Reinigungsnebel bricht den Panzer.
##   3 Dornenstrahlen Linien zeigen, wohin Dornen schießen; dazwischen ist man
##                   sicher. Dazu weiter Wurzelstöße. Beim Eintritt wieder Panzer.
## Gereinigt (Leben 0) setzt es cleansed_flag, lässt Knospen und eine Seite
## fallen und bleibt als verdorrter Knoten stehen. Wer verliert, wacht im
## Garten auf; das Herz ist beim nächsten Besuch wieder heil.
## Alle Werte sind Exporte, Balancing = Zahlen in der Szene ändern.
## Entwurf: docs/design/welt_und_items.md, Abschnitt 11. (Platzhalter-Zeichnung.)

enum Phase { DORMANT, ROOTS, SHIELD, RAYS, CLEANSED }

const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const SHIELD_ITEM := "potion_cleansing_mist"
const PETAL := Color("#C2307A")
const PETAL_LIGHT := Color("#E458B1")
const KNOT := Color("#2B1633")
const KNOT_LIGHT := Color("#4D2A57")
const OUTLINE := Color("#0E0A14")
const GOLD := Color("#D9A441")
const WITHERED := Color("#7C7C68")
# Bei Neumond (Moon.blight_surges) kommen Telegraphen so viel schneller.
const SURGE_TELEGRAPH := 0.8

## Unter dieser ID meldet es sich beim Grimoire.
@export var heart_id: String = "bloom_heart_1"
## Wird beim Reinigen gesetzt (öffnet z. B. den Blütennebel für immer).
@export var cleansed_flag: String = "bloom_heart_1_cleansed"
@export var max_health: int = 36
## Ab diesem Anteil Leben beginnt Phase 2 bzw. 3.
@export_range(0.0, 1.0) var shield_at: float = 0.65
@export_range(0.0, 1.0) var rays_at: float = 0.3
## So nah muss die Hexe kommen, damit es erwacht.
@export var wake_distance: float = 150.0

@export_group("Wurzelstöße")
@export var root_interval: float = 2.4
@export var root_telegraph: float = 0.9
@export var root_count: int = 3
@export var root_radius: float = 16.0
@export var root_spread: float = 44.0
@export var root_damage: int = 1

@export_group("Knospenpanzer")
@export var minion_scene: PackedScene = preload("res://scenes/world/blight_beetle.tscn")
@export var minion_count: int = 2
## Nach dem Reinigungsnebel so lange wehrlos (keine Angriffe).
@export var mist_stun: float = 2.5

@export_group("Dornenstrahlen")
@export var ray_interval: float = 3.6
@export var ray_telegraph: float = 1.0
@export var ray_count: int = 6
@export var ray_length: float = 230.0
@export var ray_width: float = 8.0
@export var ray_damage: int = 1

@export_group("Belohnung")
## Seite, die beim Reinigen fällt (data/grimoire/pages/). Leer = keine.
@export var page_id: String = "page_journal_02"
@export var drop_item: String = "bloom_bud"
@export var drop_amount: int = 3

var health := 36
var phase := Phase.DORMANT

var _player: Player
var _root_timer := 0.0
var _ray_timer := 0.0
var _stun := 0.0
var _flash := 0.0
var _beat := 0.0
var _shielded := false
var _minions: Array[Node] = []
var _shield_done_for: Array[Phase] = []
var _message_wait := 0.0
var _glow: Glow
var _light: NightLight


func _ready() -> void:
	health = max_health
	collision_layer = WORLD_LAYER | ENEMY_LAYER
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	add_child(shape)
	# Trefferzone in Größe der Knospe, damit Zauber auf Brusthöhe treffen.
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = ENEMY_LAYER
	hitbox.collision_mask = 0
	var hitbox_shape := CollisionShape2D.new()
	var hitbox_rect := RectangleShape2D.new()
	hitbox_rect.size = Vector2(40, 40)
	hitbox_shape.shape = hitbox_rect
	hitbox_shape.position = Vector2(0, -20)
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)
	_light = NightLight.new()
	_light.texture = preload("res://assets/effects/lights/light_round_64.png")
	_light.color = PETAL
	_light.base_energy = 0.9
	_light.texture_scale = 2.0
	_light.position = Vector2(0, -22)
	add_child(_light)
	_glow = Glow.new()
	_glow.heart = self
	add_child(_glow)
	if WorldState.has_flag(cleansed_flag):
		_wither()
		return
	add_to_group("blighted")
	add_to_group("potion_target")


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_message_wait = maxf(_message_wait - delta, 0.0)
	_beat += delta * (1.0 + 0.5 * int(phase))
	queue_redraw()
	_glow.queue_redraw()
	if phase == Phase.CLEANSED:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	if phase == Phase.DORMANT:
		if _player.global_position.distance_to(global_position) < wake_distance:
			_wake()
		return
	if _shielded:
		_check_minions()
	if _stun > 0.0:
		_stun -= delta
		return
	_root_timer -= delta
	if _root_timer <= 0.0:
		_root_timer = root_interval * (0.8 if phase == Phase.RAYS else 1.0)
		_strike_roots()
	if phase == Phase.RAYS:
		_ray_timer -= delta
		if _ray_timer <= 0.0:
			_ray_timer = ray_interval
			_fire_rays()


func _wake() -> void:
	phase = Phase.ROOTS
	_root_timer = 1.0
	Messages.post(tr("MSG_HEART_AWAKENS"))
	Sfx.play_at("combat/beetle_warn", global_position)
	(_player.get_node("Combat") as Combat).set_active(true)


func is_shielded() -> bool:
	return _shielded


## Getroffen (Zauber, Sichel, Würfe). Mit Panzer prallt alles ab.
func take_hit(damage: int, _knockback: Vector2, _stagger: bool = true) -> void:
	if phase == Phase.CLEANSED:
		return
	if phase == Phase.DORMANT and _player:
		_wake()
	if _shielded:
		CombatFx.sparks(get_parent(), global_position + Vector2(0, -22), GOLD, 6, 30.0)
		if _message_wait <= 0.0:
			_message_wait = 3.0
			Messages.deny(tr("MSG_HEART_SHIELDED"))
		return
	health -= damage
	_flash = 0.12
	Sfx.play_at("combat/hit", global_position)
	if health <= 0:
		_cleanse()
	elif phase == Phase.ROOTS and health <= max_health * shield_at:
		_enter(Phase.SHIELD)
	elif phase == Phase.SHIELD and health <= max_health * rays_at:
		_enter(Phase.RAYS)


## Ein Wurf ist hier gelandet (Gruppe potion_target). Reinigungsnebel
## bricht den Panzer und lähmt das Herz kurz.
func on_potion(item: ItemData) -> bool:
	if phase == Phase.CLEANSED or item == null or item.id != SHIELD_ITEM:
		return false
	if _shielded:
		_break_shield()
	_stun = mist_stun
	CombatFx.sparks(get_parent(), global_position + Vector2(0, -22), item.throw_color, 24, 50.0)
	return true


func _enter(new_phase: Phase) -> void:
	phase = new_phase
	if not _shield_done_for.has(new_phase):
		_shield_done_for.append(new_phase)
		_raise_shield()
	if new_phase == Phase.RAYS:
		_ray_timer = 1.5


func _raise_shield() -> void:
	_shielded = true
	Messages.post(tr("MSG_HEART_CLOSES"))
	Sfx.play_at("combat/beetle_warn", global_position)
	_minions.clear()
	for i in minion_count:
		var minion: Node2D = minion_scene.instantiate()
		var angle := TAU * i / maxf(minion_count, 1) + PI / 4.0
		minion.position = position + Vector2.from_angle(angle) * 56.0
		get_parent().add_child.call_deferred(minion)
		_minions.append(minion)


func _check_minions() -> void:
	for minion in _minions:
		if is_instance_valid(minion) and minion.is_in_group("blighted"):
			return
	# Ein Käfer, der noch nicht im Baum ist, zählt auch als lebendig.
	for minion in _minions:
		if is_instance_valid(minion) and not minion.is_inside_tree():
			return
	_break_shield()


func _break_shield() -> void:
	_shielded = false
	Messages.post(tr("MSG_HEART_OPENS"))
	Sfx.play_at("combat/burst", global_position)


func _telegraph_time(seconds: float) -> float:
	return seconds * (SURGE_TELEGRAPH if Moon.blight_surges() else 1.0)


func _strike_roots() -> void:
	for i in root_count:
		var strike := RootStrike.new()
		strike.radius = root_radius
		strike.damage = root_damage
		strike.telegraph = _telegraph_time(root_telegraph)
		# Der erste Ring liegt unter der Hexe, die anderen in der Nähe.
		var offset := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(root_spread * 0.5, root_spread)
		get_parent().add_child(strike)
		strike.global_position = (_player.global_position + offset).round()


func _fire_rays() -> void:
	var rays := ThornRays.new()
	rays.count = ray_count
	rays.length = ray_length
	rays.width = ray_width
	rays.damage = ray_damage
	rays.telegraph = _telegraph_time(ray_telegraph)
	rays.rotation_offset = randf() * TAU
	add_child(rays)
	rays.position = Vector2(0, -12)


## Reinigen: Die Blüte fällt ab, das Gebiet atmet auf.
func _cleanse() -> void:
	phase = Phase.CLEANSED
	_shielded = false
	remove_from_group("blighted")
	remove_from_group("potion_target")
	for child in get_children():
		if child is ThornRays:
			child.queue_free()
	for minion in _minions:
		if is_instance_valid(minion) and minion.has_method("take_hit"):
			minion.take_hit(999, Vector2.ZERO)
	WorldState.set_flag(cleansed_flag)
	Grimoire.report("cleanse", {"id": heart_id})
	Sfx.play_at("combat/cleanse", global_position)
	Messages.post(tr("MSG_HEART_CLEANSED"))
	CombatFx.sparks(get_parent(), global_position + Vector2(0, -22), PETAL, 60, 90.0)
	for i in drop_amount:
		var drop := DroppedItem.new()
		drop.item_id = drop_item
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector2.from_angle(TAU * i / drop_amount) * 30.0 + Vector2(0, 16)
	if page_id != "" and not Grimoire.is_page_found(page_id):
		var page: Node2D = preload("res://scenes/world/loose_page.tscn").instantiate()
		page.page_id = page_id
		get_parent().add_child(page)
		page.global_position = global_position + Vector2(0, 34)
	_wither()


## Verdorrt: kein Licht mehr, kein Gegner, nur noch ein Hindernis.
func _wither() -> void:
	phase = Phase.CLEANSED
	_light.enabled = false
	$Hitbox.set_deferred("collision_layer", 0)
	collision_layer = WORLD_LAYER


## Wurzelknoten mit Knospe in der Mitte, Licht von oben links. Pro Phase
## öffnet sich die Knospe weiter. Gereinigt: grau und eingefallen.
func _draw() -> void:
	var cleansed := phase == Phase.CLEANSED
	var knot := WITHERED.darkened(0.4) if cleansed else KNOT
	var knot_light := WITHERED if cleansed else KNOT_LIGHT
	if _flash > 0.0:
		knot = Color("#C6B8BE")
		knot_light = Color("#EADFCB")
	# Wurzeln, die in den Boden greifen.
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(side * 18.0 - (6.0 if side < 0 else 0.0), -6, 6, 4), OUTLINE)
		draw_rect(Rect2(side * 24.0 - (4.0 if side < 0 else 0.0), -3, 4, 3), OUTLINE)
		draw_rect(Rect2(side * 18.0 - (5.0 if side < 0 else 0.0), -5, 4, 2), knot)
	# Der Knoten.
	draw_rect(Rect2(-18, -30, 36, 28), OUTLINE)
	draw_rect(Rect2(-16, -32, 32, 32), OUTLINE)
	draw_rect(Rect2(-16, -30, 32, 28), knot)
	draw_rect(Rect2(-15, -30, 10, 20), knot_light)
	draw_rect(Rect2(2, -24, 2, 18), OUTLINE)
	draw_rect(Rect2(-8, -14, 2, 12), OUTLINE)


## Knospe, Panzer und Herzschlag leuchten (unbeleuchtete Ebene).
class Glow:
	extends Node2D

	var heart: BloomHeart

	func _ready() -> void:
		material = CombatFx.unshaded()

	func _draw() -> void:
		if heart.phase == Phase.CLEANSED:
			draw_rect(Rect2(-4, -38, 8, 6), WITHERED.darkened(0.2))
			return
		var pulse := 0.5 + 0.5 * sin(heart._beat * TAU * 0.8)
		var open := 0
		match heart.phase:
			Phase.SHIELD:
				open = 1
			Phase.RAYS:
				open = 2
		if heart.is_shielded():
			# Geschlossen: harte Bordeaux-Blätter mit Goldnaht.
			draw_rect(Rect2(-9, -46, 18, 18), OUTLINE)
			draw_rect(Rect2(-8, -45, 16, 16), Color("#6E1830"))
			draw_rect(Rect2(-1, -45, 2, 16), GOLD)
			draw_rect(Rect2(-8, -38, 16, 2), GOLD)
			return
		# Offene Blätter, je Phase weiter.
		var spread := 4 + open * 3
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2(side * spread - (6.0 if side < 0 else 0.0), -44 + open, 6, 12), PETAL)
			draw_rect(Rect2(side * spread - (6.0 if side < 0 else 0.0), -44 + open, 2, 4), PETAL_LIGHT)
		draw_rect(Rect2(-5, -48, 10, 16), PETAL)
		draw_rect(Rect2(-4, -47, 3, 5), PETAL_LIGHT)
		# Herz in der Mitte, pulsiert.
		var core := GOLD.lerp(Color("#FFB566"), pulse)
		draw_rect(Rect2(-2, -42 + open, 4, 4 + roundi(pulse * 2.0)), core)


## Ein Wurzelstoß: Ring am Boden füllt sich, dann stoßen Wurzeln hoch und
## treffen, wer im Ring steht. Liegt flach unter allem.
class RootStrike:
	extends Node2D

	const ACTIVE := 0.3

	var radius := 16.0
	var damage := 1
	var telegraph := 0.9
	var _time := 0.0
	var _struck := false

	func _ready() -> void:
		z_index = Decor.FLAT_Z
		material = CombatFx.unshaded()

	func _process(delta: float) -> void:
		_time += delta
		if not _struck and _time >= telegraph:
			_struck = true
			_hit()
		if _time >= telegraph + ACTIVE:
			queue_free()
		queue_redraw()

	func _hit() -> void:
		Sfx.play_at("combat/burst", global_position)
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.global_position.distance_to(global_position) <= radius + 4.0:
			var vitals: Vitals = player.get_node("Vitals")
			if vitals.take_damage(damage):
				vitals.make_invulnerable(0.6)

	func _draw() -> void:
		if not _struck:
			var progress := clampf(_time / telegraph, 0.0, 1.0)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 20, Color(PETAL, 0.6), 1.0)
			draw_circle(Vector2.ZERO, radius * progress, Color(PETAL, 0.25 + 0.3 * progress))
			return
		# Wurzeln: dunkle Spitzen mit Magenta-Rand.
		for i in 6:
			var at := Vector2.from_angle(TAU * i / 6.0) * radius * 0.5
			draw_rect(Rect2(at.x - 1, at.y - 10, 3, 10), OUTLINE)
			draw_rect(Rect2(at.x, at.y - 9, 1, 8), PETAL_LIGHT)


## Dornenstrahlen: gepunktete Linien zeigen die Richtungen, dann schießen
## Dornen entlang. Wer zwischen den Linien steht, ist sicher.
class ThornRays:
	extends Node2D

	const ACTIVE := 0.35

	var count := 6
	var length := 230.0
	var width := 8.0
	var damage := 1
	var telegraph := 1.0
	var rotation_offset := 0.0
	var _time := 0.0
	var _hit_done := false

	func _ready() -> void:
		z_index = Decor.FLAT_Z
		material = CombatFx.unshaded()

	func _process(delta: float) -> void:
		_time += delta
		if _time >= telegraph and not _hit_done:
			_hit_done = true
			_hit()
		if _time >= telegraph + ACTIVE:
			queue_free()
		queue_redraw()

	func direction(i: int) -> Vector2:
		return Vector2.from_angle(rotation_offset + TAU * i / count)

	func _hit() -> void:
		Sfx.play_at("combat/slash_heavy", global_position)
		var player := get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return
		var offset := player.global_position + Vector2(0, -8) - global_position
		for i in count:
			var along := offset.dot(direction(i))
			var across := absf(offset.dot(direction(i).orthogonal()))
			if along > 0.0 and along <= length and across <= width:
				var vitals: Vitals = player.get_node("Vitals")
				if vitals.take_damage(damage):
					vitals.make_invulnerable(0.6)
				return

	func _draw() -> void:
		var active := _time >= telegraph
		var progress := clampf(_time / telegraph, 0.0, 1.0)
		for i in count:
			var dir := direction(i)
			var side := dir.orthogonal() * width
			if active:
				# Dornen: durchgehende Linie mit Zacken.
				draw_line(dir * 12.0, dir * length, PETAL, 3.0)
				var along := 16.0
				while along < length:
					draw_line(dir * along, dir * along + side * 0.8 - dir * 4.0, PETAL_LIGHT, 1.0)
					along += 14.0
				continue
			# Kurz vor dem Schuss dicht und hell, vorher locker und blasser.
			var color := Color(PETAL_LIGHT, 1.0) if progress >= 0.8 else Color(PETAL, 0.55 + 0.45 * progress)
			var step := 6.0 if progress < 0.8 else 3.0
			var along := 12.0
			while along <= length:
				for edge: float in [-1.0, 1.0]:
					draw_rect(Rect2((dir * along + side * edge).round(), Vector2(2, 2)), color)
				along += step
