extends Control

## Leben (Bordeaux) und Hexenkraft (Magenta) als zwei schmale Leisten oben
## links. Sichtbar im Kampfmodus oder solange etwas nicht voll ist, sonst
## ausgeblendet, damit der ruhige Alltag im Garten nicht vollgestellt ist.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)

const WIDTH := 64
const HEALTH_COLOR := Color("#A3243C")
const HEALTH_LIGHT := Color("#D4475E")
const POWER_COLOR := Color("#C2307A")
const POWER_LIGHT := Color("#E458B1")
const BACK := Color("#0E0A14")
const FRAME := Color("#4D1230")

var _player: Player
var _vitals: Vitals


func _ready() -> void:
	add_to_group("clock")
	position = Vector2(6, 24)
	size = Vector2(WIDTH + 2, 13)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if _vitals == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
		_vitals = _player.get_node("Vitals")
	modulate.a = 1.0 if _player.combat_mode or not _vitals.is_full() else 0.0
	queue_redraw()


func _draw() -> void:
	if _vitals == null:
		return
	_bar(0, float(_vitals.health) / _vitals.max_health, HEALTH_COLOR, HEALTH_LIGHT)
	_bar(7, _vitals.power / _vitals.max_power(), POWER_COLOR, POWER_LIGHT)


func _bar(y: float, fraction: float, color: Color, light: Color) -> void:
	var rect := Rect2(0, y, WIDTH + 2, 6)
	draw_rect(rect, FRAME)
	draw_rect(rect.grow(-1), BACK)
	var filled := floorf(WIDTH * clampf(fraction, 0.0, 1.0))
	if filled > 0:
		draw_rect(Rect2(1, y + 1, filled, 4), color)
		draw_rect(Rect2(1, y + 1, filled, 1), light)
