extends CharacterBody2D

# Pixel pro Sekunde. Mit @export lässt sich der Wert im Inspector anpassen,
# ohne das Script zu öffnen.
@export var speed: float = 80.0
# Wie weit vor den Füßen nach etwas gesucht wird, womit man interagieren kann.
@export var interaction_distance: float = 16.0

# Blickrichtung, immer eine der vier Hauptrichtungen. Wird später auch
# für die Laufanimation gebraucht.
var facing := Vector2.DOWN

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea


func _physics_process(_delta: float) -> void:
	# get_vector liefert die Richtung schon normalisiert, damit die Hexe
	# diagonal nicht schneller läuft als gerade.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	# move_and_slide rechnet delta selbst ein und berücksichtigt Kollisionen.
	move_and_slide()

	# Beim Stehenbleiben die letzte Richtung behalten.
	if direction != Vector2.ZERO:
		facing = _to_four_directions(direction)
		interaction_area.position = body_shape.position + facing * interaction_distance


# _unhandled_input bekommt nur Eingaben, die nicht schon z. B. von der UI
# abgefangen wurden – so interagiert die Hexe später nicht "durch" eine
# offene Dialogbox hindurch.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _find_closest_interactable()
		if target:
			target.interact(self)


func _find_closest_interactable() -> Interactable:
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
