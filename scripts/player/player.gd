extends CharacterBody2D

# Pixel pro Sekunde. Mit @export lässt sich der Wert im Inspector anpassen,
# ohne das Script zu öffnen.
@export var speed: float = 80.0


func _physics_process(_delta: float) -> void:
	# get_vector liefert die Richtung schon normalisiert, damit die Hexe
	# diagonal nicht schneller läuft als gerade.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	# move_and_slide rechnet delta selbst ein und berücksichtigt Kollisionen.
	move_and_slide()
