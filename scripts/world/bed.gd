extends StaticBody2D

## Das Bett: Die Hexe schläft den Tag durch und wacht zur nächsten Nacht auf.
## (Das Hexenfeuer ist dagegen nur Zeitraffer.) Beim Schlafen wird gespeichert.

const EMPTY_TEXTURE := preload("res://assets/environment/props/bed.png")
const SLEEPING_TEXTURE := preload("res://assets/environment/props/bed_sleeping.png")
# Kurze Pausen, damit man die schlafende Hexe sieht, bevor es schwarz wird
# und bevor sie wieder aufsteht.
const FALL_ASLEEP_TIME := 0.8
const DARK_TIME := 0.8
const WAKE_UP_TIME := 0.6

var _sleeping := false

@onready var sprite: Sprite2D = $Sprite2D
# Wo die Hexe nach dem Aufwachen steht. Ein Marker2D ist ein unsichtbarer
# Punkt, den man im Editor einfach verschieben kann.
@onready var wake_spot: Marker2D = $WakeSpot


func _ready() -> void:
	# Main sucht das Bett beim Spielstart, um die Hexe daneben aufwachen zu lassen.
	add_to_group("bed")


func _on_interactable_interacted(player: Node2D) -> void:
	if not _sleeping:
		_sleep(player as Player)


func _sleep(player: Player) -> void:
	_sleeping = true
	player.set_controls_enabled(false)
	player.hide()
	sprite.texture = SLEEPING_TEXTURE
	await get_tree().create_timer(FALL_ASLEEP_TIME).timeout
	await ScreenFade.fade_out()

	DayCycle.sleep_until_night()
	# Erst nach dem Wachstum über Nacht speichern, damit der Stand zum
	# Aufwachen passt.
	SaveGame.save_game()
	await get_tree().create_timer(DARK_TIME).timeout

	await ScreenFade.fade_in()
	await get_tree().create_timer(WAKE_UP_TIME).timeout
	sprite.texture = EMPTY_TEXTURE
	player.global_position = wake_spot.global_position
	player.facing = Vector2.DOWN
	player.show()
	player.set_controls_enabled(true)
	_sleeping = false
	# Bewusst kein Text am Morgen: Was über den Tag passiert ist, soll man
	# selbst im Garten entdecken.
