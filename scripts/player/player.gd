class_name Player
extends CharacterBody2D

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

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var float_sparkles: CPUParticles2D = $FloatSparkles


func _ready() -> void:
	# Damit z. B. das Pausemenü die Hexe findet, ohne ihren Pfad zu kennen.
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# get_vector liefert die Richtung schon normalisiert, damit die Hexe
	# diagonal nicht schneller läuft als gerade.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var floating := Input.is_action_pressed("float") and direction != Vector2.ZERO
	velocity = direction * speed * (float_speed_factor if floating else 1.0)
	# move_and_slide rechnet delta selbst ein und berücksichtigt Kollisionen.
	move_and_slide()

	# Beim Stehenbleiben die letzte Richtung behalten.
	if direction != Vector2.ZERO:
		facing = _to_four_directions(direction)
		interaction_area.position = body_shape.position + facing * interaction_distance

	_update_animation(direction != Vector2.ZERO, floating)
	_update_float(delta, floating)


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
	var direction_name := "side"
	if facing == Vector2.UP:
		direction_name = "up"
	elif facing == Vector2.DOWN:
		direction_name = "down"
	animated_sprite.flip_h = facing == Vector2.LEFT
	# play() mit der laufenden Animation startet sie nicht neu, daher
	# darf das jeden Frame aufgerufen werden.
	animated_sprite.play(("walk_" if is_moving and not floating else "idle_") + direction_name)


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
	if event.is_action_pressed("interact"):
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
