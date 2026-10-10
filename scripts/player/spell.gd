class_name Spell
extends Area2D

## Ein Zauber aus Digitalis: fliegt gerade zur Maus, trifft Wände und
## befallene Wesen und zerplatzt dort in Funken. Der große Spezialzauber
## platzt in einem Kreis und trifft alles darin.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)

const COLOR := Color("#E458B1")
const CORE := Color("#FFD2EC")
# Kollisionsebenen: 1 Welt, 3 befallene Wesen (project.godot).
const WORLD_LAYER := 1
const ENEMY_LAYER := 4

var direction := Vector2.RIGHT
var speed := 220.0
var max_distance := 180.0
var damage := 1
# 0 = trifft nur, was es berührt; sonst platzt es in diesem Umkreis.
var burst_radius := 0.0
var radius := 3.0
# Wie stark Getroffenes weggestoßen wird.
var knockback := 90.0

var _travelled := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = WORLD_LAYER | ENEMY_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	z_index = 3
	var material_unshaded := CanvasItemMaterial.new()
	material_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = material_unshaded
	# Ein kleines Licht, damit der Zauber nachts die Umgebung erhellt.
	var light := PointLight2D.new()
	light.texture = preload("res://assets/effects/lights/light_round_32.png")
	light.color = COLOR
	light.energy = 0.9
	add_child(light)
	var trail := CPUParticles2D.new()
	trail.amount = 10
	trail.lifetime = 0.25
	trail.local_coords = false
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 2.0
	trail.initial_velocity_max = 8.0
	trail.spread = 180.0
	trail.color = COLOR
	trail.use_parent_material = true
	add_child(trail)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step := direction * speed * delta
	global_position += step
	_travelled += step.length()
	if _travelled >= max_distance:
		_burst()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 1, Color(COLOR, 0.5))
	draw_circle(Vector2.ZERO, radius, COLOR)
	draw_circle(Vector2(-1, -1), radius * 0.4, CORE)


func _on_body_entered(body: Node2D) -> void:
	if _done or body is Player:
		return
	if burst_radius <= 0.0 and body.has_method("take_hit"):
		body.take_hit(damage, direction * knockback)
	_burst()


## Wesen haben eine eigene Trefferzone (Area2D) in Größe ihres Sprites;
## getroffen wird dann das Wesen, dem die Zone gehört. Andere Zonen
## (Ausgänge, Interaktion …) liegen auf anderen Ebenen und zählen nicht.
func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer & ENEMY_LAYER:
		_on_body_entered(area.get_parent())


## Zerplatzen: Funken, und beim großen Zauber alles im Umkreis treffen.
func _burst() -> void:
	_done = true
	if burst_radius > 0.0:
		for enemy in get_tree().get_nodes_in_group("blighted"):
			var offset := (enemy as Node2D).global_position - global_position
			if offset.length() <= burst_radius and enemy.has_method("take_hit"):
				enemy.take_hit(damage, offset.normalized() * knockback)
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 12 if burst_radius <= 0.0 else 40
	sparks.lifetime = 0.4
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 40)
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 50.0 if burst_radius <= 0.0 else burst_radius * 2.5
	sparks.color = COLOR
	sparks.material = material
	sparks.z_index = 3
	get_parent().add_child(sparks)
	sparks.global_position = global_position
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	queue_free()
