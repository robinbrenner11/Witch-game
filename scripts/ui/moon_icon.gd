extends Control

## Die Mondphase als kleines Pixelbild unter der Uhr. Gezeichnet statt als
## Grafik, weil sich alle 8 Phasen aus einer Formel ergeben: Für jedes Pixel
## der Scheibe wird geprüft, ob es auf der beleuchteten Seite der
## Schattengrenze liegt (zunehmend rechts hell, abnehmend links).

# Mond mit 11 Pixeln Durchmesser, jedes Pixel doppelt so groß gezeichnet wie
# die übrige UI (Hotbar, Uhr).
const RADIUS := 5
const PIXEL := 2
const LIT := Color("#EADFCB")
# Die dunkle Seite bleibt schwach sichtbar, damit man auch den Neumond sieht.
const DARK := Color("#344678")

var _phase := -1


func _process(_delta: float) -> void:
	if DayCycle.moon_phase() != _phase:
		_phase = DayCycle.moon_phase()
		queue_redraw()


func _draw() -> void:
	# 0 = Neumond, 0.5 = Vollmond, gegen 1 wieder Neumond.
	var cycle := float(_phase) / DayCycle.MOON_PHASE_NAMES.size()
	var diameter := RADIUS * 2 + 1
	for py in diameter:
		for px in diameter:
			var dx := (px - RADIUS) / (RADIUS + 0.5)
			var dy := (py - RADIUS) / (RADIUS + 0.5)
			if dx * dx + dy * dy > 1.0:
				continue
			# Wo auf dieser Zeile die Schattengrenze liegt.
			var edge := sqrt(1.0 - dy * dy) * cos(TAU * cycle)
			var lit := dx > edge if cycle <= 0.5 else dx < -edge
			draw_rect(Rect2(Vector2(px, py) * PIXEL, Vector2.ONE * PIXEL), LIT if lit else DARK)
