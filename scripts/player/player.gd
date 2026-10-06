class_name Player
extends CharacterBody2D

# Pixel pro Sekunde. Mit @export lässt sich der Wert im Inspector anpassen,
# ohne das Script zu öffnen.
@export var speed: float = 80.0
# Wie weit vor den Füßen nach etwas gesucht wird, womit man interagieren kann.
@export var interaction_distance: float = 16.0

# Blickrichtung, immer eine der vier Hauptrichtungen. Wird später auch
# für die Laufanimation gebraucht.
var facing := Vector2.DOWN
# Welche Samen die Hexe gerade "in der Hand" hat und per E pflanzt.
var selected_seed: PlantData = null

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_select_next_seed()


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

	_update_animation(direction != Vector2.ZERO)


# Animationsnamen setzen sich aus Zustand und Richtung zusammen, z. B.
# "walk_side". Für links gibt es kein eigenes Sheet – die Seitenansicht
# wird einfach gespiegelt.
func _update_animation(is_moving: bool) -> void:
	var direction_name := "side"
	if facing == Vector2.UP:
		direction_name = "up"
	elif facing == Vector2.DOWN:
		direction_name = "down"
	animated_sprite.flip_h = facing == Vector2.LEFT
	# play() mit der laufenden Animation startet sie nicht neu, daher
	# darf das jeden Frame aufgerufen werden.
	animated_sprite.play(("walk_" if is_moving else "idle_") + direction_name)


# _unhandled_input bekommt nur Eingaben, die nicht schon z. B. von der UI
# abgefangen wurden – so interagiert die Hexe später nicht "durch" eine
# offene Dialogbox hindurch.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _find_closest_interactable()
		if target:
			target.interact(self)
	elif event.is_action_pressed("next_seed"):
		_select_next_seed()


# Nur zum Testen per Q, bis die Hotbar kommt. Springt zur nächsten Samensorte,
# von der noch etwas da ist (am Ende wieder von vorn).
func _select_next_seed() -> void:
	var seed_ids := Inventory.item_ids().filter(
		func(item_id: String) -> bool:
			return item_id.begins_with("seed_") and Inventory.count(item_id) > 0
	)
	if seed_ids.is_empty():
		selected_seed = null
		print("Keine Samen mehr")
		return
	var index := 0
	if selected_seed != null:
		index = (seed_ids.find(selected_seed.seed_item_id()) + 1) % seed_ids.size()
	selected_seed = PlantData.from_id(seed_ids[index].trim_prefix("seed_"))
	print("Samen gewählt: %s (%d)" % [selected_seed.display_name, Inventory.count(seed_ids[index])])


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
