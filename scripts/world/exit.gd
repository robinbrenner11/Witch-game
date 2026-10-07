@tool
class_name Exit
extends Area2D

## Ein Ausgang in einen anderen Ort (Weg aus dem Garten, Tür des Unterschlupfs).
## Läuft die Hexe hinein, blendet Main ab und lädt den Zielort; dort kommt sie
## am Ausgang mit dem Namen target_exit heraus. Jeder Ausgang ist also auch
## ein Eingang: spawn_offset sagt, wo man steht, wenn man hier ankommt.
##
## @tool: Das Script läuft auch im Editor, aber nur, um Bereich (Rahmen) und
## Ankunftspunkt (Kreuz) anzuzeigen – im Spiel ist der Ausgang unsichtbar.

const EDITOR_COLOR := Color("#C2307A")

@export_file("*.tscn") var target_scene: String = ""
# Name des Ausgangs im Zielort, an dem die Hexe herauskommt.
@export var target_exit: String = ""
# Größe des Auslösebereichs in Pixeln.
@export var size: Vector2 = Vector2(32, 32):
	set(value):
		size = value
		queue_redraw()
# Ankunftspunkt relativ zum Ausgang. Muss außerhalb des Bereichs liegen,
# sonst geht es beim Ankommen sofort wieder zurück.
@export var spawn_offset: Vector2 = Vector2.ZERO:
	set(value):
		spawn_offset = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Nur die Hexe (Layer 1) soll den Ausgang auslösen.
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(-size / 2, size), EDITOR_COLOR, false)
	draw_line(spawn_offset + Vector2(-4, 0), spawn_offset + Vector2(4, 0), EDITOR_COLOR)
	draw_line(spawn_offset + Vector2(0, -4), spawn_offset + Vector2(0, 4), EDITOR_COLOR)


func spawn_position() -> Vector2:
	return global_position + spawn_offset


func _on_body_entered(body: Node2D) -> void:
	if body is Player and target_scene != "":
		# Über die Gruppe: Der Ausgang muss nicht wissen, wo Main hängt.
		get_tree().call_group("main", "travel", target_scene, target_exit)
