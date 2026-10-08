class_name Player
extends CharacterBody2D

## Kommt, wenn eine Aktion (Ausgießen, Ernten, Trinken, Schnippen) zu Ende
## gespielt ist. Wer auf das Ende warten will, nutzt await action_finished.
signal action_finished(action: String)

# Pixel pro Sekunde. Mit @export lässt sich der Wert im Inspector anpassen,
# ohne das Script zu öffnen.
@export var speed: float = 80.0
# Mit Shift schwebt sie per Magie so viel schneller über den Boden.
@export var float_speed_factor: float = 2.5
# Wie weit vor den Füßen nach etwas gesucht wird, womit man interagieren kann.
@export var interaction_distance: float = 16.0

# Grundversatz des Sprites (Füße auf dem Ursprung, siehe docs/ASSETS.md) und
# wie viele Pixel sie beim Schweben darüber abhebt.
const SPRITE_OFFSET_Y := -32
const FLOAT_HEIGHT := 3

# Blickrichtung, immer eine der vier Hauptrichtungen. Wird später auch
# für die Laufanimation gebraucht.
var facing := Vector2.DOWN
# Welche Samen die Hexe gerade "in der Hand" hat und per E pflanzt. Ergibt
# sich aus dem gewählten Hotbar-Platz; null, wenn dort keine Samen liegen.
var selected_seed: PlantData:
	get:
		var item := ItemData.from_id(Inventory.selected_item_id())
		return item.plant() if item else null

var _float_time := 0.0
# Digitalis gezogen (Combat setzt das). Dann schaut die Hexe zur Maus statt
# in Laufrichtung, Shift ist ein Dash statt Schweben, E ruht.
var combat_mode := false
# Dash: feste Geschwindigkeit für kurze Zeit, die das Laufen ersetzt.
var _dash_velocity := Vector2.ZERO
var _dash_time := 0.0
# Läuft gerade eine Aktion, steht hier ihr Name ("pour", "harvest" …), sonst "".
var _action := ""

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var float_sparkles: CPUParticles2D = $FloatSparkles
@onready var pour_magic: PourMagic = $PourMagic


func _ready() -> void:
	# Damit z. B. das Pausemenü die Hexe findet, ohne ihren Pfad zu kennen.
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	# Während einer Aktion steht sie still. Die Aktionen sind kurz, deshalb
	# lohnt sich kein Abbrechen per Laufen.
	if is_busy():
		velocity = Vector2.ZERO
		return
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_velocity
		move_and_slide()
		return
	# get_vector liefert die Richtung schon normalisiert, damit die Hexe
	# diagonal nicht schneller läuft als gerade.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var floating := Input.is_action_pressed("float") and direction != Vector2.ZERO and not combat_mode
	velocity = direction * speed * (float_speed_factor if floating else 1.0)
	# move_and_slide rechnet delta selbst ein und berücksichtigt Kollisionen.
	move_and_slide()

	# Beim Stehenbleiben die letzte Richtung behalten. Im Kampf bestimmt das
	# Zielen die Blickrichtung (Combat ruft face_towards auf).
	if direction != Vector2.ZERO and not combat_mode:
		face_towards(direction)

	_update_animation(direction != Vector2.ZERO, floating)
	_update_float(delta, floating)


## Schaut in eine der vier Richtungen, die dieser am nächsten liegt.
func face_towards(direction: Vector2) -> void:
	facing = _to_four_directions(direction)
	interaction_area.position = body_shape.position + facing * interaction_distance


## Ein kurzer Stoß in eine Richtung (Ausweichen im Kampf).
func start_dash(dash_velocity: Vector2, seconds: float) -> void:
	_dash_velocity = dash_velocity
	_dash_time = seconds


## Spielt eine Aktion einmal in Blickrichtung ab, z. B. "pour" oder "harvest".
## Danach geht es von selbst zurück zu idle (siehe _on_animation_finished).
func play_action(action: String) -> void:
	_action = action
	_update_float(0.0, false)
	animated_sprite.play(action + "_" + _direction_name())


## Wartet, bis die laufende Aktion bei diesem Frame (ab 0) angekommen ist,
## z. B. beim Stoß des Ausgießens. Endet die Aktion vorher, geht es sofort weiter.
func wait_for_action_frame(frame: int) -> void:
	while is_busy() and animated_sprite.frame < frame:
		await animated_sprite.frame_changed


## Steht gerade eine Aktion an? Dann wird nicht gelaufen und nichts Neues begonnen.
func is_busy() -> bool:
	return _action != ""


## Darf sie gerade etwas tun? Nicht beim Schlafen oder Ortswechsel
## (Steuerung aus) und nicht mitten in einer Aktion.
func can_act() -> bool:
	return is_physics_processing() and not is_busy()


## Schaltet Laufen und Interagieren ab, z. B. während sie schläft (später
## auch bei Dialogen oder offenen Fenstern).
func set_controls_enabled(enabled: bool) -> void:
	set_physics_process(enabled)
	set_process_unhandled_input(enabled)
	# Nicht in der Luft hängen bleiben, wenn z. B. mitten im Schweben ein
	# Ortswechsel beginnt.
	_update_float(0.0, false)
	if enabled:
		# Sonst zeigt sie bis zum ersten Tastendruck noch die alte Animation.
		_update_animation(false)


# Animationsnamen setzen sich aus Zustand und Richtung zusammen, z. B.
# "walk_side". Für links gibt es kein eigenes Sheet – die Seitenansicht
# wird einfach gespiegelt. Beim Schweben bewegen sich die Beine nicht,
# deshalb dann die Steh-Pose.
func _update_animation(is_moving: bool, floating: bool = false) -> void:
	# Eine laufende Aktion nicht überschreiben, z. B. wenn beim Ortswechsel
	# die Steuerung wieder angeht.
	if is_busy():
		return
	animated_sprite.flip_h = facing == Vector2.LEFT
	# play() mit der laufenden Animation startet sie nicht neu, daher
	# darf das jeden Frame aufgerufen werden.
	animated_sprite.play(("walk_" if is_moving and not floating else "idle_") + _direction_name())


func _direction_name() -> String:
	if facing == Vector2.UP:
		return "up"
	if facing == Vector2.DOWN:
		return "down"
	return "side"


# Nur die Aktionen laufen ohne Loop, also endet hier immer eine Aktion.
func _on_animation_finished() -> void:
	var finished := _action
	_action = ""
	_update_animation(false)
	action_finished.emit(finished)


## Beim Schweben hebt sie ein paar Pixel ab, wippt sanft und hinterlässt
## magentafarbene Funken (Magenta = Magie).
func _update_float(delta: float, floating: bool) -> void:
	float_sparkles.emitting = floating
	if floating:
		_float_time += delta
		animated_sprite.offset.y = SPRITE_OFFSET_Y - FLOAT_HEIGHT + round(sin(_float_time * 6.0))
	else:
		_float_time = 0.0
		animated_sprite.offset.y = SPRITE_OFFSET_Y


# _unhandled_input bekommt nur Eingaben, die nicht schon z. B. von der UI
# abgefangen wurden – so interagiert die Hexe später nicht "durch" eine
# offene Dialogbox hindurch.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not is_busy() and not combat_mode:
		var target := find_closest_interactable()
		if target:
			target.interact(self)
			# Dieselbe E-Taste soll nicht gleich ein eben geöffnetes Fenster
			# wieder schließen.
			get_viewport().set_input_as_handled()


func find_closest_interactable() -> Interactable:
	var closest: Interactable = null
	var closest_distance := INF
	for area in interaction_area.get_overlapping_areas():
		if area is Interactable:
			var distance := interaction_area.global_position.distance_to(area.global_position)
			if distance < closest_distance:
				closest = area as Interactable
				closest_distance = distance
	return closest


# Diagonal zählt die stärkere Achse; bei exakt diagonal gewinnt hoch/runter.
func _to_four_directions(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0)
	return Vector2(0, signf(direction.y))
