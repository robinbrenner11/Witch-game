class_name GardenGate
extends Node2D

## Gartentor in einer Zaunlücke. Es schwingt auf, sobald die Hexe davor steht,
## und fällt wieder zu, wenn sie weg ist. Nur geschlossen ist es ein Hindernis.
## Ursprung = Pfostenfuß in der Kachel, die das Tor ersetzt (wie beim Zaun).
## Der Zaun findet Tore über die Gruppe "fence_gate" (in der Szene gesetzt).

@export var texture: Texture2D
@export var frame_count: int = 4
@export var fps: float = 8.0
# Kollision im geschlossenen Zustand (waagerechtes Tor: flacher Streifen).
@export var closed_collision: Vector2 = Vector2(32, 6)
# Wie nah die Hexe kommen muss, damit es aufgeht.
@export var sense_size: Vector2 = Vector2(48, 72)
## Bleibt verriegelt, bis dieses Flag gesetzt ist (WorldState), z. B. die
## Hexenpforte, die erst der Nachtwächter öffnet. Leer = nie verriegelt.
@export var required_flag: String = ""
## Meldung, wenn die Hexe vor dem verriegelten Tor steht (Text-Schlüssel).
@export var locked_message: String = "MSG_GATE_LOCKED"

var _sprite: AnimatedSprite2D
var _blocker: CollisionShape2D
# Wie viele Körper gerade davor stehen. Später vielleicht auch Begleiter.
var _visitors := 0


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Decor.strip_frames(texture, frame_count, fps, false)
	# Kachel liegt so, dass ihr Pfostenfuß (y = 28) auf dem Ursprung steht.
	_sprite.offset = Vector2(0, -12)
	add_child(_sprite)

	var body := StaticBody2D.new()
	_blocker = _make_shape(closed_collision, Vector2(0, -closed_collision.y / 2.0))
	body.add_child(_blocker)
	add_child(body)

	var sense := Area2D.new()
	# Nur die Hexe (Layer 1) zählt.
	sense.collision_layer = 0
	sense.collision_mask = 1
	sense.add_child(_make_shape(sense_size, Vector2.ZERO))
	sense.body_entered.connect(_on_body_entered)
	sense.body_exited.connect(_on_body_exited)
	add_child(sense)


func _make_shape(size: Vector2, at: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	return shape


func is_locked() -> bool:
	return required_flag != "" and not WorldState.has_flag(required_flag)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_visitors += 1
	if is_locked():
		Messages.deny(tr(locked_message))
		return
	# set_deferred: Kollisionen darf man nicht mitten in der Physik-Abfrage ändern.
	_blocker.set_deferred("disabled", true)
	_sprite.play()


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_visitors = maxi(_visitors - 1, 0)
	# Nur schließen, was auch offen war (ein verriegeltes Tor ging gar nicht auf).
	if _visitors == 0 and _blocker.disabled:
		_blocker.set_deferred("disabled", false)
		_sprite.play_backwards()
