class_name CombatPotions
extends Node2D

## Trank-Schnellzugriff im Kampf. Q benutzt den gewählten Kampftrank, R
## wechselt zur nächsten Sorte. Kampftränke sind Wurftränke (ItemData.Use.THROW)
## und Heiltränke (Trinken mit heal > 0); welche es gibt, ergibt sich aus der
## Tasche, ohne Menü und ohne eigene Ausrüstung.
##
## Wurftränke: Q halten zeigt einen Kreis in Wirkgröße an der Maus,
## Loslassen wirft. Der Trank fliegt im Bogen und landet genau dort
## (höchstens MAX_RANGE weit). Werfen kostet keine Hexenkraft.
## Design: game_design.md, Abschnitt 7 (Entscheidungen vom 10.10.).
## Eigener Node unter dem Player, damit player.gd und combat.gd klein bleiben.

signal changed

# Weiter fliegt ein Trank nicht; der Kreis bleibt dann am Rand stehen.
const MAX_RANGE := 200.0
# Wo der Trank die Hand verlässt, relativ zu den Füßen der Hexe.
const HAND_OFFSET := Vector2(0, -30)

## Gewählte Sorte (Item-ID), "" = keine Kampftränke in der Tasche.
var selected_id := ""

var _aiming := false
var _aim_circle: AimCircle

@onready var player: Player = get_parent()
@onready var combat: Combat = $"../Combat"
@onready var vitals: Vitals = $"../Vitals"


func _ready() -> void:
	_aim_circle = AimCircle.new()
	_aim_circle.top_level = true
	_aim_circle.visible = false
	_aim_circle.z_index = 9
	add_child(_aim_circle)
	Inventory.changed.connect(_validate)
	combat.mode_changed.connect(func(_active: bool) -> void: _cancel_aim())
	_validate()


static func is_combat_potion(item: ItemData) -> bool:
	return item != null and (item.use == ItemData.Use.THROW or (item.use == ItemData.Use.DRINK and item.heal > 0))


## Alle Kampftrank-Sorten in der Tasche, in der Reihenfolge der Plätze.
func available() -> Array[String]:
	var result: Array[String] = []
	for slot in Inventory.SIZE:
		var item_id := Inventory.item_in_slot(slot)
		if item_id != "" and not result.has(item_id) and is_combat_potion(ItemData.from_id(item_id)):
			result.append(item_id)
	return result


func select_next() -> void:
	var ids := available()
	if ids.size() <= 1:
		return
	selected_id = ids[(ids.find(selected_id) + 1) % ids.size()]
	Sfx.play("ui/item_pick")
	changed.emit()


func is_aiming() -> bool:
	return _aiming


func _unhandled_input(event: InputEvent) -> void:
	if not combat.active or not player.is_physics_processing():
		return
	if event.is_action_released("potion_quick"):
		if _aiming:
			_throw()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("potion_next"):
		select_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("potion_quick"):
		_use_selected()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _aiming:
		return
	if not combat.active:
		_cancel_aim()
		return
	_aim_circle.global_position = target_point().round()
	_aim_circle.queue_redraw()


## Wo ein Wurf landen würde: an der Maus, aber nicht weiter als MAX_RANGE.
func target_point() -> Vector2:
	var hand := player.global_position + HAND_OFFSET
	var to_mouse := get_global_mouse_position() - hand
	return hand + to_mouse.limit_length(MAX_RANGE)


func _use_selected() -> void:
	var item := ItemData.from_id(selected_id)
	if item == null:
		Messages.deny(tr("MSG_NO_COMBAT_POTION"))
		return
	if item.use == ItemData.Use.DRINK:
		_drink(item)
	else:
		_aiming = true
		_aim_circle.radius = item.throw_radius
		_aim_circle.color = item.throw_color
		_aim_circle.visible = true
		_process(0.0)


## Trinken im Kampf ist eine Entscheidung: Die Hexe steht kurz still.
func _drink(item: ItemData) -> void:
	if player.is_busy() or not Inventory.remove(item.id):
		return
	player.play_action("drink")
	Sfx.play("brewing/drink")
	# Die Wirkung setzt ein, wenn sie das Fläschchen absetzt (Frame 4).
	await player.wait_for_action_frame(3)
	# Funken beim Heilen kommen von VitalsFeedback.
	vitals.heal(item.heal)
	# Wie jeder getrunkene Trank gibt er auch etwas Hexenkraft zurück.
	vitals.restore_power(PotionEffects.POTION_POWER)
	Messages.post(tr("MSG_HEALED"))


func _throw() -> void:
	var item := ItemData.from_id(selected_id)
	var target := target_point()
	_cancel_aim()
	if item == null or not Inventory.remove(item.id):
		return
	var level := get_tree().get_first_node_in_group("level") as Level
	if level == null:
		return
	var potion := ThrownPotion.new()
	potion.item = item
	potion.from = player.global_position
	potion.to = target
	level.objects.add_child(potion)
	Sfx.play("ui/item_drop")


func _cancel_aim() -> void:
	_aiming = false
	if _aim_circle:
		_aim_circle.visible = false


## Behält die Auswahl, solange die Sorte noch in der Tasche ist; sonst die erste.
func _validate() -> void:
	var ids := available()
	var before := selected_id
	if not ids.has(selected_id):
		selected_id = ids[0] if not ids.is_empty() else ""
	if selected_id != before:
		_cancel_aim()
	changed.emit()


## Zielkreis in Wirkgröße an der Maus, gestrichelt, damit er nicht wie ein
## Treffer aussieht.
class AimCircle:
	extends Node2D

	var radius := 32.0
	var color := Color.WHITE

	func _ready() -> void:
		material = CombatFx.unshaded()

	func _draw() -> void:
		var dashes := 16
		for i in dashes:
			var start := TAU * i / dashes
			draw_arc(Vector2.ZERO, radius, start, start + TAU / dashes * 0.55, 4, Color(color, 0.85), 1.0)
		draw_rect(Rect2(-1, -1, 2, 2), color)


## Ein geworfener Trank: fliegt im Bogen von der Hand zum Ziel, sein Schatten
## gleitet am Boden mit. Beim Aufschlag platzt er (BURST) oder hinterlässt
## eine Zone (ZONE).
class ThrownPotion:
	extends Node2D

	const START_HEIGHT := 30.0
	const ARC_HEIGHT := 28.0
	const SPEED := 260.0

	var item: ItemData
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _time := 0.0
	var _duration := 0.4
	var _height := START_HEIGHT

	func _ready() -> void:
		_duration = clampf(from.distance_to(to) / SPEED, 0.25, 0.6)
		material = CombatFx.unshaded()
		z_index = 4
		global_position = from

	func _process(delta: float) -> void:
		_time += delta
		var t := clampf(_time / _duration, 0.0, 1.0)
		global_position = from.lerp(to, t).round()
		_height = lerpf(START_HEIGHT, 0.0, t) + ARC_HEIGHT * 4.0 * t * (1.0 - t)
		queue_redraw()
		if t >= 1.0:
			_land()

	func _draw() -> void:
		# Schatten am Boden, Fläschchen in der Luft (dreht sich im Flug).
		draw_rect(Rect2(-3, -1, 6, 2), Color(0.05, 0.04, 0.08, 0.5))
		var y := -roundf(_height)
		var tilt := 1.0 if fmod(_time * 12.0, 2.0) < 1.0 else 0.0
		draw_rect(Rect2(-2, y - 6 + tilt, 4, 6), Color("#2B1633"))
		draw_rect(Rect2(-1, y - 5 + tilt, 2, 4), item.throw_color)
		draw_rect(Rect2(-1, y - 8 + tilt, 2, 2), Color("#8A5240"))

	func _land() -> void:
		set_process(false)
		var parent := get_parent()
		# Auch die Welt kann auf Würfe reagieren (z. B. Ranken, die brennen).
		for target in get_tree().get_nodes_in_group("potion_target"):
			if (target as Node2D).global_position.distance_to(to) <= item.throw_radius + 24.0:
				target.on_potion(item)
		match item.throw_effect:
			ItemData.ThrowEffect.BURST:
				# Schaden trifft nur befallene Wesen, nie die Hexe.
				for enemy in get_tree().get_nodes_in_group("blighted"):
					var offset: Vector2 = (enemy as Node2D).global_position - to
					if offset.length() <= item.throw_radius and enemy.has_method("take_hit"):
						enemy.take_hit(item.throw_damage, offset.normalized() * 160.0)
				var ring := CombatFx.Ring.new(item.throw_radius, item.throw_color)
				parent.add_child(ring)
				ring.global_position = to
				CombatFx.sparks(parent, to + Vector2(0, -4), item.throw_color, 30, item.throw_radius * 2.5)
				_flash(parent)
				Sfx.play_at("combat/burst", to)
			ItemData.ThrowEffect.ZONE:
				var zone := ThornZone.new()
				zone.item = item
				parent.add_child(zone)
				zone.global_position = to
				Sfx.play_at("garden/pour_sludge", to)
		queue_free()

	## Kurzer Lichtblitz beim Platzen, damit man es auch nachts sieht.
	func _flash(parent: Node) -> void:
		var light := PointLight2D.new()
		light.texture = preload("res://assets/effects/lights/light_round_64.png")
		light.color = item.throw_color
		light.texture_scale = item.throw_radius * 2.5 / 64.0
		light.energy = 1.8
		parent.add_child(light)
		light.global_position = to
		var tween := light.create_tween()
		tween.tween_property(light, "energy", 0.0, 0.35)
		tween.tween_callback(light.queue_free)


## Dornennebel am Boden: verlangsamt alles darin (auch die Hexe) und schadet
## befallenen Wesen alle zone_tick Sekunden. Liegt flach unter allem.
class ThornZone:
	extends Node2D

	const FADE := 0.4

	var item: ItemData
	var _left := 0.0
	var _tick := 0.0
	var _time := 0.0
	var _modifier := ""

	func _ready() -> void:
		_left = item.zone_time
		_tick = item.zone_tick
		_modifier = "thorns_%d" % get_instance_id()
		z_index = Decor.FLAT_Z
		material = CombatFx.unshaded()

	func _exit_tree() -> void:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			player.remove_speed_modifier(_modifier)

	func _process(delta: float) -> void:
		_time += delta
		_left -= delta
		_tick -= delta
		var tick_now := _tick <= 0.0
		if tick_now:
			_tick = item.zone_tick
		for enemy in get_tree().get_nodes_in_group("blighted"):
			if (enemy as Node2D).global_position.distance_to(global_position) <= item.throw_radius:
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(item.zone_slow, 0.25)
				if tick_now and enemy.has_method("take_hit"):
					enemy.take_hit(item.throw_damage, Vector2.ZERO, false)
		# Effekte treffen auch die Hexe (Entscheidung 10.10.), Schaden nicht.
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			if player.global_position.distance_to(global_position) <= item.throw_radius:
				player.set_speed_modifier(_modifier, item.zone_slow)
			else:
				player.remove_speed_modifier(_modifier)
		queue_redraw()
		if _left <= 0.0:
			queue_free()

	func _draw() -> void:
		var alpha := clampf(minf(_time, _left) / FADE, 0.0, 1.0)
		var r := item.throw_radius
		var color := item.throw_color
		draw_circle(Vector2.ZERO, r, Color("#2B3A1E", 0.35 * alpha))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color, 0.7 * alpha), 1.0)
		# Dornen: kleine Spitzen an festen Stellen, wippen leicht.
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 14:
			var spot := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, r - 4.0)
			var sway := 1.0 if sin(_time * 5.0 + i) > 0.0 else 0.0
			spot = spot.round()
			draw_rect(Rect2(spot + Vector2(0, -3 - sway), Vector2(1, 3 + sway)), Color(color, alpha))
			draw_rect(Rect2(spot + Vector2(-1, -1), Vector2(3, 1)), Color("#5C7A2E", alpha))
			draw_rect(Rect2(spot + Vector2(0, -4 - sway), Vector2(1, 1)), Color("#C2307A", alpha))
