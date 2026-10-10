extends Node2D

## Getrunkene Tränke und ihre Wirkung auf die Hexe. Eigener Node unter dem
## Player, damit player.gd klein bleibt. Q oder Rechtsklick trinkt das Item
## in der Hand, falls es ein Trank zum Trinken ist (ItemData.use = DRINK).
##
## Alle Wirkungen halten bis zum Ende der Nacht, also bis zum nächsten
## Tageswechsel (Schlafen oder 18 Uhr).

# Wo das Irrlicht relativ zu den Füßen der Hexe schwebt: oben links neben dem Kopf.
const WISP_OFFSET := Vector2(-14, -46)
# Wie schnell es hinterherkommt (höher = enger an der Hexe).
const WISP_FOLLOW := 3.0
const ENDLESS_NIGHT_FACTOR := 1.5

var _time := 0.0
var _wisp_position := Vector2.ZERO

# Das Irrlicht ist "top_level": Es bewegt sich nicht automatisch mit der Hexe,
# sondern fliegt ihr in _process mit etwas Verzögerung hinterher.
@onready var wisp: Node2D = $Wisp
@onready var moonlight: NightLight = $Moonlight


func _ready() -> void:
	DayCycle.day_passed.connect(_on_day_passed)
	_end_all()


func _unhandled_input(event: InputEvent) -> void:
	# Beim Schlafen oder Ortswechsel ist die Steuerung aus.
	if event.is_action_pressed("use_item") and (get_parent() as Player).can_act():
		_drink_selected()


func _process(delta: float) -> void:
	if not wisp.visible:
		return
	_time += delta
	var target := global_position + WISP_OFFSET + Vector2(0, sin(_time * 2.5) * 3.0)
	# Nähert sich dem Ziel jeden Frame ein Stück: weiches Hinterherschweben,
	# unabhängig von der Bildrate.
	_wisp_position = _wisp_position.lerp(target, 1.0 - exp(-delta * WISP_FOLLOW))
	wisp.global_position = _wisp_position.round()


func _drink_selected() -> void:
	var item := ItemData.from_id(Inventory.selected_item_id())
	if item == null or item.use != ItemData.Use.DRINK:
		return
	# Sofort aus dem Inventar, damit derselbe Trank nicht doppelt getrunken wird.
	Inventory.remove(item.id)
	var player := get_parent() as Player
	player.play_action("drink")
	# Die Wirkung setzt ein, wenn sie das Fläschchen absetzt (Frame 4).
	await player.wait_for_action_frame(3)
	# Jede Trinkwirkung ist eigenes Verhalten, deshalb hier im Code statt
	# als Zahlen in den Item-Daten.
	match item.id:
		"potion_will_o_wisp":
			_wisp_position = global_position + WISP_OFFSET
			wisp.show()
			Sfx.play("brewing/wisp_appear")
			Messages.post(tr("MSG_WISP_JOINS"))
		"potion_liquid_moonlight":
			moonlight.enabled = true
			Sfx.play("brewing/moonlight")
			Messages.post(tr("MSG_NIGHT_CLEAR"))
		"potion_endless_night":
			DayCycle.lengthen_night(ENDLESS_NIGHT_FACTOR)
			Sfx.play("brewing/endless_night")
			Messages.post(tr("MSG_NIGHT_STRETCHES"))


func _on_day_passed(_day: int) -> void:
	_end_all()


func _end_all() -> void:
	wisp.hide()
	moonlight.enabled = false
