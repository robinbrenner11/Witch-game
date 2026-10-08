class_name DroppedItem
extends Area2D

## Ein Item, das auf dem Boden liegt (z. B. was ein gereinigter Käfer
## fallen lässt). Es wippt leicht und landet in der Tasche, sobald die Hexe
## darüberläuft. Ist die Tasche voll, bleibt es liegen.

const WORLD_LAYER := 1

var item_id := ""
var amount := 1

var _time := 0.0
var _icon: Texture2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = WORLD_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_icon = Inventory.icon_for(item_id)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_time * 3.0) * 1.5)
	draw_rect(Rect2(-6, -2, 12, 3), Color(0.05, 0.04, 0.08, 0.4))
	if _icon:
		draw_texture(_icon, Vector2(-8, -18 + bob))


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if Inventory.add(item_id, amount):
		Messages.post("+%d %s" % [amount, Inventory.display_name_for(item_id)])
		queue_free()
	else:
		Messages.post(tr("MSG_BAG_FULL"))
