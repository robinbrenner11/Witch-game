extends StaticBody2D

## Der Kessel: E öffnet das Brau-Fenster. Was hineinkommt und was dabei
## herauskommt, regelt das Fenster (und Brewing); der Kessel in der Welt
## blubbert nur vor sich hin.

const FRAME_TIME := 0.4

var _frame_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer >= FRAME_TIME:
		_frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes


func _on_interactable_interacted(_player: Node2D) -> void:
	# Über die Gruppe statt über einen festen Pfad: Der Kessel muss nicht
	# wissen, wo in der Szene das Fenster hängt.
	var window := get_tree().get_first_node_in_group("brew_window") as BrewWindow
	if window:
		window.open()
