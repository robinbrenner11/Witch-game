class_name LongShadow
extends Node2D

## Zunehmender Mond (Nächte 2–3): Draußen fällt der Schatten der Hexe nicht
## mehr nur unter sie, sondern streckt sich lang zu etwas Verborgenem in der
## Nähe: einer losen Grimoire-Seite oder etwas Reifem, das sie noch nie
## gesammelt hat. Keine Anzeige, kein Pfeil: Wer darauf achtet, entdeckt
## mehr. Mother Moss deutet es an (Gespräch bei zunehmendem Mond).
##
## Gezeichnet als verjüngter Streifen aus ganzen Pixeln (keine Drehung eines
## Bildes, damit die Kanten hart bleiben).

## Wer in diese Gruppe kommt, braucht is_secret() -> bool.
const GROUP := "long_shadow_lure"
const RANGE := 360.0
# Ab hier ist man da, der Schatten zieht sich zurück.
const NEAR := 36.0
const LENGTH := 76.0
const WIDTH := 9.0
# Gedämpftes Magenta: ein magischer Schatten. Reines Dunkel geht auf dem
# nächtlichen Boden unter.
const COLOR := Color("#5C1E4E")
const ALPHA := 0.7
const FADE_SPEED := 1.5
# Nicht jeden Frame die ganze Gruppe absuchen.
const SEARCH_INTERVAL := 0.4

var target: Node2D
var _strength := 0.0
var _search_wait := 0.0
var _time := 0.0


func _ready() -> void:
	# Unter der Hexe, auf Höhe des normalen Schattens.
	z_index = -5
	position = Vector2(2, 1)


func _process(delta: float) -> void:
	_time += delta
	_search_wait -= delta
	if _search_wait <= 0.0:
		_search_wait = SEARCH_INTERVAL
		target = find_target() if is_active() else null
	var want := 0.0
	if target and is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		want = clampf((distance - NEAR) / NEAR, 0.0, 1.0)
	_strength = move_toward(_strength, want, FADE_SPEED * delta)
	queue_redraw()


## Nur draußen und nur bei zunehmendem Mond.
func is_active() -> bool:
	if Moon.phase() != Moon.Phase.WAXING:
		return false
	var level := get_tree().get_first_node_in_group("level") as Level
	return level == null or not level.indoors


func find_target() -> Node2D:
	var best: Node2D = null
	var best_distance := RANGE
	for node in get_tree().get_nodes_in_group(GROUP):
		var lure := node as Node2D
		if lure == null or not lure.is_inside_tree() or not lure.call("is_secret"):
			continue
		var distance := global_position.distance_to(lure.global_position)
		if distance < best_distance:
			best = lure
			best_distance = distance
	return best


func _draw() -> void:
	if _strength <= 0.01 or target == null or not is_instance_valid(target):
		return
	var direction := (target.global_position - global_position).normalized()
	# Leichtes Atmen in der Länge, damit er lebendig wirkt.
	var length := LENGTH * (0.9 + 0.1 * sin(_time * 1.7))
	var color := Color(COLOR, ALPHA * _strength)
	var drawn := {}
	var steps := int(length / 2.0)
	for i in steps:
		var t := float(i) / steps
		var center := direction * (6.0 + i * 2.0)
		var half := maxf(WIDTH * (1.0 - t) * 0.5, 0.5)
		# Ganze 2-Pixel-Blöcke, doppelte überspringen (sonst dunkler).
		for offset in range(-ceili(half), ceili(half) + 1):
			var p := center + Vector2(-direction.y, direction.x) * offset
			var cell := Vector2i(floori(p.x / 2.0), floori(p.y / 2.0))
			if drawn.has(cell):
				continue
			drawn[cell] = true
			draw_rect(Rect2(Vector2(cell * 2), Vector2(2, 2)), color)
