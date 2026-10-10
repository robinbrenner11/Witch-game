extends Node2D

## Geisterhaft blaue Kuppeln über jedem Nachtschatten, der gerade hemmt.
## Ein einziger Shader zeichnet alle zusammen, dadurch verschmelzen Kuppeln
## nebeneinander zu einer Glocke. Dieses Script sagt dem Shader nur, wo die
## Kuppeln stehen, und lässt sie pochen.
##
## Muss in der Szene über (nach) den Pflanzen liegen und an Position (0, 0)
## stehen, weil der Shader in Weltkoordinaten rechnet.

# Muss zu MAX_DOMES im Shader passen.
const MAX_DOMES := 32
# So weit reicht die gezeichnete Fläche über die Mittelpunkte hinaus: Kuppel
# (49 breit, 60 hoch, 47 tief) plus ausgefranster Nebelrand und Verschmelzen.
const MARGIN_SIDE := 64.0
const MARGIN_TOP := 76.0
const MARGIN_BOTTOM := 64.0
# Pochen: Intensität je Phase und wie lange sie gehalten wird (Ruhe länger).
const PULSE: Array[float] = [0.0, 0.5, 1.0, 0.5]
const PULSE_TIMES: Array[float] = [0.7, 0.18, 0.26, 0.18]

var _area := Rect2()
var _phase := 0
var _phase_time := 0.0
# Leises Wabern, solange irgendwo eine Kuppel steht. Ein Player für alle,
# in der Mitte der Kuppeln.
var _hum: AudioStreamPlayer2D


func _ready() -> void:
	_hum = Sfx.make_loop_player("garden/nightshade_loop", 0.0, 240.0)
	_hum.autoplay = false
	add_child(_hum)
	Garden.plant_changed.connect(_on_garden_plant_changed)
	_update_domes()


func _process(delta: float) -> void:
	_phase_time += delta
	if _phase_time >= PULSE_TIMES[_phase]:
		_phase_time = 0.0
		_phase = (_phase + 1) % PULSE.size()
		material.set_shader_parameter("intensity", PULSE[_phase])


func _on_garden_plant_changed(_cell: Vector2i) -> void:
	_update_domes()


func _update_domes() -> void:
	var centers := PackedVector2Array()
	for cell in Garden.active_aura_cells(PlantData.AuraEffect.BLOCK_GROWTH):
		if centers.size() == MAX_DOMES:
			break
		# Mitte des Beet-Tiles.
		centers.append(Vector2(cell * Garden.TILE_SIZE) + Vector2.ONE * Garden.TILE_SIZE / 2.0)
	visible = not centers.is_empty()
	if not visible:
		_hum.stop()
		return
	var middle := Vector2.ZERO
	for center in centers:
		middle += center
	_hum.global_position = middle / centers.size()
	if not _hum.playing:
		_hum.play()

	# Gezeichnet wird nur ein Rechteck um alle Kuppeln, nicht die ganze Welt.
	var top_left := centers[0]
	var bottom_right := centers[0]
	for center in centers:
		top_left = top_left.min(center)
		bottom_right = bottom_right.max(center)
	top_left -= Vector2(MARGIN_SIDE, MARGIN_TOP)
	bottom_right += Vector2(MARGIN_SIDE, MARGIN_BOTTOM)
	_area = Rect2(top_left, bottom_right - top_left)

	material.set_shader_parameter("center_count", centers.size())
	# Der Shader erwartet immer ein volles Array, der Rest bleibt ungenutzt.
	centers.resize(MAX_DOMES)
	material.set_shader_parameter("centers", centers)
	queue_redraw()


func _draw() -> void:
	# Weiß, weil der Shader die Farbe ohnehin selbst bestimmt.
	draw_rect(_area, Color.WHITE)
