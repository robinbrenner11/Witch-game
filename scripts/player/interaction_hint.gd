extends Node2D

## Goldene Eckklammern um das, womit E gerade interagieren würde (bei einem
## Beet genau um das Tile). So sieht man, was gemeint ist, bevor man drückt –
## auch wenn die Hexe davor steht.
##
## Die Größe kommt aus der Form des Interactables, deshalb braucht kein Objekt
## eine eigene Einstellung. Hängt unter dem Player, ist aber "top_level": Er
## bewegt sich nicht mit der Hexe, sondern wird jeden Frame aufs Ziel gesetzt.

const COLOR := Color("#D9A441")
# Länge der Klammer-Arme in Pixeln.
const ARM := 4

var _rect := Rect2()
var _time := 0.0

@onready var player: Player = get_parent()


func _process(delta: float) -> void:
	var target := player.find_closest_interactable()
	# Beim Schlafen ist die Steuerung und damit auch der Hinweis aus.
	visible = target != null and player.can_act() and not player.combat_mode
	if not visible:
		return
	_time += delta
	# Ein Pixel Atmen: Die Klammern gehen langsam etwas auseinander.
	var grow := 1.0 if sin(_time * 4.0) > 0.0 else 0.0
	_rect = _target_rect(target).grow(grow)
	queue_redraw()


func _draw() -> void:
	var left := _rect.position.x
	var top := _rect.position.y
	# Letzte Pixelspalte bzw. -zeile innerhalb des Rechtecks.
	var right := _rect.end.x - 1
	var bottom := _rect.end.y - 1
	# Je Ecke ein waagerechter und ein senkrechter Arm, nach innen zeigend.
	for corner: Vector2 in [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]:
		var arm_x := corner.x if corner.x == left else corner.x - ARM + 1
		var arm_y := corner.y if corner.y == top else corner.y - ARM + 1
		draw_rect(Rect2(arm_x, corner.y, ARM, 1), COLOR)
		draw_rect(Rect2(corner.x, arm_y, 1, ARM), COLOR)


## Rechteck der ersten rechteckigen Kollisionsform des Interactables, in
## ganzen Welt-Pixeln.
func _target_rect(target: Interactable) -> Rect2:
	for child in target.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var size: Vector2 = child.shape.size
			var center: Vector2 = child.global_position
			return Rect2((center - size / 2).round(), size.round())
	return Rect2(target.global_position.round() - Vector2(8, 8), Vector2(16, 16))
