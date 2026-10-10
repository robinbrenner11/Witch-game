extends StaticBody2D

## Der Kessel: E öffnet das Brau-Fenster oder holt einen fertigen Trank ab.
## Was im Kessel passiert, steht in Brewing; der Kessel in der Welt zeigt es
## nur: Beim Brauen glüht er magenta, ein fertiger Trank schwebt darüber.

const FRAME_TIME := 0.4
const IDLE_GLOW := Color("#62A06E")
# Magenta = Magie (Palette): Hier passiert gerade etwas.
const BREWING_GLOW := Color("#C2307A")

var _frame_timer := 0.0
var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var potion_icon: Sprite2D = $PotionIcon
@onready var glow: NightLight = $Glow


func _ready() -> void:
	Brewing.changed.connect(_update_look)
	_update_look()
	# Der Kessel blubbert immer leise vor sich hin, nah lauter als fern.
	add_child(Sfx.make_loop_player("brewing/cauldron_loop", -4.0, 260.0))


func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer >= FRAME_TIME:
		_frame_timer = 0.0
		sprite.frame = (sprite.frame + 1) % sprite.hframes
	# Der fertige Trank schwebt leicht wippend über dem Sud. round() hält ihn
	# auf ganzen Pixeln.
	_time += delta
	potion_icon.position.y = -38 + round(sin(_time * 3.0) * 1.5)


func _on_interactable_interacted(_player: Node2D) -> void:
	if Brewing.finished_potion() != "":
		if Brewing.take_finished():
			Sfx.play("brewing/potion_take")
		else:
			Messages.deny(tr("MSG_BAG_FULL"))
		return
	# Über die Gruppe statt über einen festen Pfad: Der Kessel muss nicht
	# wissen, wo in der Szene das Fenster hängt.
	var window := get_tree().get_first_node_in_group("brew_window") as BrewWindow
	if window:
		window.open()


func _update_look() -> void:
	var finished := Brewing.finished_potion()
	potion_icon.texture = Inventory.icon_for(finished) if finished != "" else null
	glow.color = BREWING_GLOW if Brewing.is_brewing() else IDLE_GLOW
