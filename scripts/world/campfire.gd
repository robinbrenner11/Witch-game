extends StaticBody2D

## Das Hexenfeuer: Hier rastet die Hexe und lässt die Zeit schneller vergehen.
## E startet die Rast, E oder ein Schritt in irgendeine Richtung beendet sie.
## Bei Einbruch der Nacht hört der Zeitraffer von selbst auf (DayCycle).

const FRAME_TIME := 0.15

var _frame_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_child(Sfx.make_loop_player("world/campfire_loop", -2.0, 280.0))


func _process(delta: float) -> void:
	# Die Flammen flackern schneller, solange die Zeit rast.
	_frame_timer += delta * (4.0 if DayCycle.fast_forward else 1.0)
	if _frame_timer >= FRAME_TIME:
		_frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes


func _on_interactable_interacted(_player: Node2D) -> void:
	DayCycle.fast_forward = not DayCycle.fast_forward
	if DayCycle.fast_forward:
		Sfx.play("world/fast_forward")


func _unhandled_input(event: InputEvent) -> void:
	if not DayCycle.fast_forward:
		return
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		if event.is_action_pressed(action):
			DayCycle.fast_forward = false
			return
