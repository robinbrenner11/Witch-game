class_name Combat
extends Node2D

## Kampfmodus der Hexe (F): Sie zieht Digitalis und zielt mit der Maus.
## Digitalis hat Formen (Stab, Sichel …), jede mit einem leichten Angriff
## (Linksklick, gedrückt halten = weiter angreifen) und einem starken
## (Rechtsklick, kurzes Ausholen, die Hexe läuft dabei langsamer). Formwechsel
## mit 1–4 oder dem Mausrad, sofort und ohne Wartezeit. Shift: Ausweichen in
## Laufrichtung (im Stehen zur Maus), kurz unverwundbar, bricht ein Ausholen ab.
##
## Was eine Form kann, steht in data/digitalis/<form>.tres (DigitalisForm,
## AttackData); hier steht nur, wie Angriffe ablaufen. Alles kostet
## Hexenkraft (Vitals). Im Kampfmodus ruhen Ernten, Ausgießen und Schnippen;
## Tränke laufen über den Schnellzugriff (CombatPotions). Im Garten und im
## Unterschlupf (sichere Zonen) bleibt Digitalis ruhig.
## Eigener Node unter dem Player, damit player.gd klein bleibt.
## Design: docs/design/game_design.md, Abschnitt 7; docs/COMBAT_SYSTEM.md.

signal mode_changed(active: bool)
signal form_changed(form: DigitalisForm)

enum State { READY, WINDUP }

const DASH_COST := 1.0
const DASH_COOLDOWN := 0.5
const DASH_SPEED := 420.0
const DASH_TIME := 0.14
# Nach dem Dash so lange unverwundbar (etwas länger als der Dash selbst).
const DASH_INVULNERABLE := 0.25
# Ein Klick kurz vor Ende der Abklingzeit geht nicht verloren, sondern wird
# nachgeholt (so fühlt sich schnelles Klicken nicht "verschluckt" an).
const BUFFER_TIME := 0.15
# "Nicht genug Hexenkraft" höchstens so oft melden.
const NO_POWER_MESSAGE_GAP := 1.2
# Nachbilder beim Ausweichen, alle so viele Sekunden eins.
const AFTERIMAGE_GAP := 0.035
# Wo der Fuß von Digitalis steht, relativ zu den Füßen der Hexe. Der große
# Stab steht neben ihr (nie vor dem Gesicht) und schwebt 2 px über dem Boden,
# so enden Stab und Kopf auf gleicher Höhe. Werte aus docs/ASSETS.md.
const STAFF_FOOT := {
	Vector2.DOWN: Vector2(14, -2),
	Vector2.UP: Vector2(-12, -2),
	Vector2.RIGHT: Vector2(12, -2),
	Vector2.LEFT: Vector2(-12, -2),
}

var active := false
var state := State.READY
var form_index := 0

var reticle: Reticle
var staff: Digitalis

var _forms: Array[DigitalisForm] = []
var _cooldown := 0.0
var _dash_cooldown := 0.0
var _dash_left := 0.0
var _afterimage_timer := 0.0
# Ausholen: welcher Angriff gleich auslöst und wie lange noch.
var _pending: AttackData
var _windup_left := 0.0
# Gepufferter Klick: welcher Angriff (true = stark) und wie lange er gilt.
var _buffered_heavy := false
var _buffer_left := 0.0
# Linke Maustaste gehalten: leichter Angriff wiederholt sich.
var _light_held := false
var _slash_mirrored := false
var _no_power_cooldown := 0.0

@onready var player: Player = get_parent()
@onready var vitals: Vitals = $"../Vitals"


func _ready() -> void:
	reticle = Reticle.new()
	reticle.top_level = true
	reticle.z_index = 10
	reticle.visible = false
	add_child(reticle)
	staff = Digitalis.new()
	staff.visible = false
	add_child(staff)
	Grimoire.changed.connect(_refresh_forms)
	_refresh_forms()


func _unhandled_input(event: InputEvent) -> void:
	if not player.is_physics_processing():
		return
	if event.is_action_pressed("combat"):
		set_active(not active)
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event.is_action_released("attack_light"):
		_light_held = false
		return
	var handled := true
	if event.is_action_pressed("attack_light"):
		_light_held = true
		request_attack(false)
	elif event.is_action_pressed("attack_heavy"):
		request_attack(true)
	elif event.is_action_pressed("float"):
		_dash()
	elif event.is_action_pressed("hotbar_next"):
		select_form(form_index + 1)
	elif event.is_action_pressed("hotbar_previous"):
		select_form(form_index - 1)
	else:
		handled = false
		for i in 4:
			if event.is_action_pressed("hotbar_%d" % (i + 1)):
				select_form(i, false)
				handled = true
	if handled:
		get_viewport().set_input_as_handled()


func set_active(value: bool) -> void:
	if value and _in_safe_zone():
		Messages.post(tr("MSG_SAFE_ZONE"))
		return
	if value == active:
		return
	active = value
	player.combat_mode = active
	reticle.visible = active
	staff.visible = active
	_light_held = false
	_buffer_left = 0.0
	_cancel_windup()
	if active:
		_refresh_forms()
		staff.set_form(current_form().id if current_form() else "staff")
	_place_staff()
	mode_changed.emit(active)


func current_form() -> DigitalisForm:
	if _forms.is_empty():
		return null
	return _forms[clampi(form_index, 0, _forms.size() - 1)]


func known_forms() -> Array[DigitalisForm]:
	return _forms.duplicate()


## Wechselt zur Form mit diesem Index. wrap: über das Ende hinaus rundum
## (Mausrad); ohne wrap zählt nur, was es gibt (Tasten 1–4).
func select_form(index: int, wrap: bool = true) -> void:
	if _forms.is_empty():
		return
	if wrap:
		index = wrapi(index, 0, _forms.size())
	elif index < 0 or index >= _forms.size():
		return
	if index == form_index:
		return
	form_index = index
	# Wechsel ist sofort möglich (Kombos), ein laufendes Ausholen verfällt.
	_cancel_windup()
	staff.set_form(current_form().id)
	CombatFx.sparks(player.get_parent(), staff.tip_position(), Color("#E458B1"), 12, 30.0, -20.0)
	Sfx.play("ui/item_pick")
	form_changed.emit(current_form())


## Ein Angriff der aktuellen Form. Während der Abklingzeit wird er kurz
## gepuffert; beim Ausholen ist schon einer unterwegs.
func request_attack(heavy: bool) -> void:
	var form := current_form()
	# Beim Trinken (Heiltrank) steht sie kurz still und greift nicht an.
	if form == null or state == State.WINDUP or player.is_busy():
		return
	if _cooldown > 0.0:
		if _cooldown <= BUFFER_TIME:
			_buffered_heavy = heavy
			_buffer_left = BUFFER_TIME
		return
	var attack := form.heavy if heavy else form.light
	if vitals.power < attack.power_cost:
		_deny_no_power()
		return
	player.face_towards(_aim())
	if attack.windup > 0.0:
		state = State.WINDUP
		_pending = attack
		_windup_left = attack.windup
		player.set_speed_modifier("windup", attack.windup_move_factor)
		staff.charge(attack.windup)
	else:
		_fire(attack)


func is_attacking() -> bool:
	return state == State.WINDUP


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_no_power_cooldown = maxf(_no_power_cooldown - delta, 0.0)
	_update_afterimages(delta)
	if not active:
		return
	# Wer den Garten betritt, steckt Digitalis weg.
	if _in_safe_zone():
		set_active(false)
		return
	# Im Kampf schaut die Hexe dorthin, wohin sie zielt.
	player.face_towards(_aim())
	reticle.global_position = get_global_mouse_position().round()
	reticle.charge = 1.0 - _windup_left / _pending.windup if state == State.WINDUP else 0.0
	reticle.queue_redraw()
	_place_staff()
	if state == State.WINDUP:
		_windup_left -= delta
		if _windup_left <= 0.0:
			var attack := _pending
			_end_windup()
			_fire(attack)
		return
	if _buffer_left > 0.0:
		_buffer_left -= delta
		if _cooldown <= 0.0:
			_buffer_left = 0.0
			request_attack(_buffered_heavy)
			return
	if _light_held and _cooldown <= 0.0:
		request_attack(false)


func _fire(attack: AttackData) -> void:
	if not vitals.spend_power(attack.power_cost):
		_deny_no_power()
		return
	_cooldown = attack.cooldown
	staff.attack()
	var level := get_tree().get_first_node_in_group("level") as Level
	if level == null:
		return
	match attack.kind:
		AttackData.Kind.BOLT:
			var spell := Spell.new()
			spell.setup(attack, (get_global_mouse_position() - staff.tip_position()).normalized())
			level.objects.add_child(spell)
			spell.global_position = staff.tip_position()
		AttackData.Kind.SLASH:
			var slash := Slash.new()
			slash.attack = attack
			slash.source = player
			slash.aim = _aim()
			slash.mirrored = _slash_mirrored
			_slash_mirrored = not _slash_mirrored
			level.objects.add_child(slash)


func _deny_no_power() -> void:
	if _no_power_cooldown > 0.0:
		return
	_no_power_cooldown = NO_POWER_MESSAGE_GAP
	Messages.deny(tr("MSG_NO_POWER"))


func _cancel_windup() -> void:
	if state == State.WINDUP:
		_end_windup()


func _end_windup() -> void:
	state = State.READY
	_pending = null
	_windup_left = 0.0
	player.remove_speed_modifier("windup")
	staff.stop_charge()


## Stellt Digitalis je nach Blickrichtung neben die Hexe.
func _place_staff() -> void:
	staff.position = STAFF_FOOT[player.facing]
	staff.set_flipped(player.facing == Vector2.LEFT)
	# Den Stab hinter der Hexe zeichnen, wenn sie nach oben schaut.
	z_index = -1 if player.facing == Vector2.UP else 1


## Richtung von der Mitte der Hexe zur Maus.
func _aim() -> Vector2:
	var aim := get_global_mouse_position() - (player.global_position + Vector2(0, -28))
	return aim.normalized() if aim.length() > 1.0 else Vector2.DOWN


func _dash() -> void:
	if _dash_cooldown > 0.0 or player.is_busy() or not vitals.spend_power(DASH_COST):
		return
	# Ausweichen geht immer vor: ein laufendes Ausholen bricht ab.
	_cancel_windup()
	_dash_cooldown = DASH_COOLDOWN
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = _aim()
	player.start_dash(direction.normalized() * DASH_SPEED, DASH_TIME)
	vitals.make_invulnerable(DASH_INVULNERABLE)
	_dash_left = DASH_TIME
	_afterimage_timer = 0.0
	Sfx.play("player/float_start")


## Während des Ausweichens bleiben kurze Nachbilder in Magenta zurück.
func _update_afterimages(delta: float) -> void:
	if _dash_left <= 0.0:
		return
	_dash_left -= delta
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_afterimage_timer = AFTERIMAGE_GAP
		var ghost := CombatFx.Afterimage.new(player.animated_sprite)
		player.get_parent().add_child(ghost)
		ghost.global_position = player.global_position


func _in_safe_zone() -> bool:
	var level := get_tree().get_first_node_in_group("level") as Level
	return level == null or level.safe_zone


func _refresh_forms() -> void:
	var current_id := current_form().id if current_form() else ""
	_forms.clear()
	for form_id in Grimoire.known_forms():
		var form := DigitalisForm.from_id(form_id)
		if form:
			_forms.append(form)
	var index := 0
	for i in _forms.size():
		if _forms[i].id == current_id:
			index = i
	form_index = index


## Kleines Fadenkreuz an der Maus, solange Digitalis gezogen ist. Beim
## Ausholen schließt sich ein Ring darum: Wenn er zu ist, löst der Angriff aus.
class Reticle:
	extends Node2D

	var charge := 0.0

	func _draw() -> void:
		for offset: Vector2 in [Vector2(-5, 0), Vector2(4, 0), Vector2(0, -5), Vector2(0, 4)]:
			var size := Vector2(2, 1) if offset.y == 0 else Vector2(1, 2)
			draw_rect(Rect2(offset, size), Spell.COLOR)
		draw_rect(Rect2(0, 0, 1, 1), Spell.CORE)
		if charge > 0.0:
			draw_arc(Vector2(0.5, 0.5), 8.0, -PI / 2.0, -PI / 2.0 + TAU * charge, 16, Spell.CORE, 1.0)
