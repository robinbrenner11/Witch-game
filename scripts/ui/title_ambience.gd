class_name TitleAmbience
extends Control

## Stimmung hinter dem Titelmenü, ganz aus Pixeln gezeichnet (Platzhalter,
## bis es ein Titelbild gibt): Mondsichel, dunkle Hügelkante, Fingerhut am
## Rand, zwei Kerzen mit warmen Lichtinseln und magenta Funken, die langsam
## aufsteigen. Dunkelheit mit warmen Inseln, wie im Spiel selbst.
## Koordinaten in 1×-Pixeln (320×180), die Szene skaliert ×2.

const SIZE := Vector2(320, 180)
const BONE := Color("#EADFCB")
const AUBERGINE := Color("#2B1633")
const NIGHT := Color("#141B3A")
const CANDLE := Color("#FFB566")
const MAGIC := Color("#E458B1")
const BACKGROUND := Color("#0E0A14")
# Lichtinsel von außen nach innen: Bordeaux, Gold, Kerzenlicht (wärmer als
# reines Kerzenlicht mit wenig Deckkraft, das auf Schwarz grau wirkt).
const GLOW: Array[Color] = [Color("#6E1830"), Color("#D9A441"), Color("#FFB566")]
# Zwei Kerzen links und rechts vom Menü (Fußpunkt).
const CANDLES: Array[Vector2] = [Vector2(58, 150), Vector2(262, 152)]
# Fingerhüte an der Hügelkante (oben links der Zeichnung, siehe BookStyle).
const FOXGLOVES: Array[Vector2] = [Vector2(18, 143), Vector2(30, 147), Vector2(284, 141), Vector2(296, 146)]
const MOTES := 14
# Wie oft die Flammen ihre Form wechseln (Sekunden).
const FLICKER_STEP := 0.14

var _time := 0.0
var _flicker := 0.0
var _flame_frame := 0
var _motes: Array[Vector3] = []  # x, y, Tempo
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE
	_rng.seed = 7
	for i in MOTES:
		_motes.append(Vector3(_rng.randf_range(10, 310), _rng.randf_range(20, 170), _rng.randf_range(3.0, 8.0)))


func _process(delta: float) -> void:
	_time += delta
	_flicker += delta
	if _flicker >= FLICKER_STEP:
		_flicker = 0.0
		_flame_frame = _rng.randi_range(0, 2)
	for i in _motes.size():
		var mote := _motes[i]
		mote.y -= mote.z * delta
		mote.x += sin(_time * 0.8 + i) * 2.0 * delta
		if mote.y < 12:
			mote = Vector3(_rng.randf_range(10, 310), 172, _rng.randf_range(3.0, 8.0))
		_motes[i] = mote
	queue_redraw()


func _draw() -> void:
	_draw_moon(Vector2(42, 30))
	_draw_hills()
	for origin in FOXGLOVES:
		BookStyle.draw_foxglove(self, origin, 0.85)
	for candle in CANDLES:
		_draw_candle(candle)
	for i in _motes.size():
		# Funken glimmen auf und ab, in harten Stufen statt weich.
		var bright := 0.4 if sin(_time * 3.0 + i * 1.7) < 0.0 else 0.9
		draw_rect(Rect2(Vector2(_motes[i].x, _motes[i].y).floor(), Vector2.ONE), Color(MAGIC, bright))


func _draw_moon(center: Vector2) -> void:
	draw_circle(center, 9, BONE)
	# Sichel: ein Kreis in Hintergrundfarbe deckt den Rest ab.
	draw_circle(center + Vector2(4, -2), 8, BACKGROUND)


## Unregelmäßige Hügelkante unten, in Nachtblau und Aubergine.
func _draw_hills() -> void:
	for x in int(SIZE.x):
		var back := 146 + roundi(4 * sin(x * 0.045) + 2 * sin(x * 0.13))
		draw_rect(Rect2(x, back, 1, SIZE.y - back), NIGHT)
		var front := 156 + roundi(3 * sin(x * 0.07 + 1.3) + 2 * sin(x * 0.21))
		draw_rect(Rect2(x, front, 1, SIZE.y - front), AUBERGINE)


func _draw_candle(foot: Vector2) -> void:
	# Lichtinsel in Stufen (keine weichen Verläufe), leicht flackernd.
	var reach := 19.0 + _flame_frame
	for ring in 3:
		draw_circle(foot + Vector2(0, -11), reach - ring * 6, Color(GLOW[ring], 0.16 + ring * 0.08))
	draw_rect(Rect2(foot + Vector2(-2, -9), Vector2(4, 9)), BONE)
	draw_rect(Rect2(foot + Vector2(-2, -9), Vector2(1, 9)), Color("#C9B9A0"))
	draw_rect(Rect2(foot + Vector2(0, -10), Vector2(1, 1)), AUBERGINE)
	var flame: Array = [[Vector2(-1, -13), Vector2(2, 3)], [Vector2(0, -14), Vector2(1, 4)], [Vector2(-1, -12), Vector2(2, 2)]][_flame_frame]
	draw_rect(Rect2(foot + flame[0], flame[1]), CANDLE)
	draw_rect(Rect2(foot + Vector2(0, -12), Vector2(1, 1)), BONE)
