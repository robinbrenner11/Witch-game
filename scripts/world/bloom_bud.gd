class_name BloomBud
extends Node2D

## Schildknospe des Blütenherzens (Phase 3): kreist um das Herz. Solange
## eine lebt, nimmt das Herz keinen Schaden. Gehört zu den Befallenen, wird
## also wie ein Käfer von Zaubern, Hieben und Würfen getroffen.

signal popped

const TEXTURE := preload("res://assets/environment/bloom_heart/bloom_bud.png")
const ENEMY_LAYER := 4
const MAX_HEALTH := 3

var health := MAX_HEALTH
var _sprite: Sprite2D
var _flash := 0.0


func _ready() -> void:
	add_to_group("blighted")
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	var light := PointLight2D.new()
	light.texture = preload("res://assets/effects/lights/light_round_32.png")
	light.color = Color("#C2307A")
	light.energy = 0.8
	add_child(light)
	# Trefferzone für Zauber (Spell erkennt Areas auf der Gegner-Ebene).
	var hitbox := Area2D.new()
	hitbox.collision_layer = ENEMY_LAYER
	hitbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	shape.position = Vector2(0, -8)
	hitbox.add_child(shape)
	add_child(hitbox)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE


func take_hit(damage: int, _knockback: Vector2, _stagger: bool = true) -> void:
	if health <= 0:
		return
	health -= damage
	_flash = 0.1
	Sfx.play_at("combat/hit", global_position)
	if health <= 0:
		remove_from_group("blighted")
		CombatFx.sparks(get_parent(), global_position + Vector2(0, -8), Color("#C2307A"), 16, 55.0)
		Sfx.play_at("combat/cleanse", global_position, -6.0)
		popped.emit()
		queue_free()
