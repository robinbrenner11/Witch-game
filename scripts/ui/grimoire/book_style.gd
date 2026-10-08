class_name BookStyle

## Farben, Maße und kleine Bausteine für das Grimoire, damit alle Seiten
## gleich aussehen. Alles aus docs/design/grimoire.md, Abschnitt 4 (Optik).
## Solange es noch keine Buchgrafiken gibt, zeichnet das Buch Einband, Papier
## und Lesezeichen selbst in diesen Farben (Platzhalter).

# --- Palette (docs/art/hexen_palette.gpl) ---
const BLACK := Color("#0E0A14")
const AUBERGINE := Color("#2B1633")
const BORDEAUX := Color("#6E1830")
const BORDEAUX_DARK := Color("#4D1230")
const BORDEAUX_DEEP := Color("#360E24")
const MAGENTA := Color("#C2307A")
const GOLD := Color("#D9A441")
const GOLD_DARK := Color("#9C6834")
const BONE := Color("#EADFCB")
const SHEET_SHADOW := Color("#C6B8BE")
const SHEET_SHADOW_DEEP := Color("#9688A0")
const LEAF_DARK := Color("#1D3436")
const WILT_OLIVE := Color("#7C7C68")
const WILT_DARK := Color("#181A28")
const MISSING := Color("#A3243C")

# --- Tinten ---
const INK := AUBERGINE                 # Fließtext
const INK_VESPERA := BORDEAUX_DEEP     # was von Vesperas Seiten stammt
const INK_VESPERA_TITLE := BORDEAUX
const INK_PLAYER := MAGENTA            # was die Spielerin selbst entdeckt
const INK_FAINT := SHEET_SHADOW_DEEP   # Nebeninfos

# --- Maße (1×, Viewport 640×360) ---
const COVER := Rect2(70, 26, 500, 312)
const LEFT_PAGE := Rect2(82, 34, 234, 296)
const RIGHT_PAGE := Rect2(324, 34, 234, 296)
const FOLD := Rect2(316, 34, 8, 296)
# Innenrand der Seiten, dort beginnt der Text.
const PAGE_MARGIN := 12
const TAB_X := 558.0
const TAB_WIDTH := 13.0
const TAB_WIDTH_ACTIVE := 18.0
const TAB_HEIGHT := 18.0
const TAB_GAP := 2.0
const TAB_GROUP_GAP := 6.0
const SLOT_SIZE := 24.0
const LINE_WIDTH := 34


## Ein Label in Buchtinte. text darf ein Übersetzungsschlüssel sein.
static func label(text: String, color: Color = INK, width: float = 0.0) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_color_override("font_color", color)
	if width > 0.0:
		result.custom_minimum_size.x = width
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Eine Überschrift mit Goldlinie darunter.
static func heading(text: String, color: Color, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label(text, color))
	box.add_child(rule(width))
	return box


## Eine Goldlinie (Akzent unter Überschriften).
static func rule(width: float) -> ColorRect:
	var line := ColorRect.new()
	line.color = GOLD_DARK
	line.custom_minimum_size = Vector2(width, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


static func icon(texture: Texture2D, tint: Color = Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.modulate = tint
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.custom_minimum_size = Vector2(16, 16)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Ein Textknopf ohne Rahmen in Buchtinte, z. B. für Filter und Verweise.
static func text_button(text: String, color: Color = INK) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, color)
	button.add_theme_color_override("font_hover_color", MAGENTA)
	var empty := StyleBoxEmpty.new()
	for style in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style, empty)
	return button


## Gepunkteter Rahmen (leere Plätze im Raster).
static func draw_dotted_rect(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	for x in range(int(rect.position.x), int(rect.end.x), 2):
		canvas.draw_rect(Rect2(x, rect.position.y, 1, 1), color)
		canvas.draw_rect(Rect2(x, rect.end.y - 1, 1, 1), color)
	for y in range(int(rect.position.y), int(rect.end.y), 2):
		canvas.draw_rect(Rect2(rect.position.x, y, 1, 1), color)
		canvas.draw_rect(Rect2(rect.end.x - 1, y, 1, 1), color)


## Ein Rahmen aus 1-Pixel-Linien (draw_rect mit filled = false wäre unscharf).
static func draw_frame(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), color)
	canvas.draw_rect(Rect2(rect.position.x, rect.end.y - 1, rect.size.x, 1), color)
	canvas.draw_rect(Rect2(rect.position, Vector2(1, rect.size.y)), color)
	canvas.draw_rect(Rect2(rect.end.x - 1, rect.position.y, 1, rect.size.y), color)


## Überwucherung der Bitterblüte (gesperrte Kapitel, befallene Seiten):
## einzelne welke Ranken, die vom oberen Rand und von den Seiten
## hineinwachsen, mit Blättern und Magenta-Knospen. Wie dicht, hängt von der
## Fläche ab; auf einem Lesezeichen sind es nur ein, zwei Ranken.
static func draw_blight(canvas: CanvasItem, rect: Rect2, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var strands := maxi(1, int(rect.size.x * rect.size.y / 2500.0))
	for i in strands:
		# Start an einem Rand, Richtung nach innen.
		var from_side := rng.randf() < 0.35
		var pos := Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.position.y)
		var direction := Vector2(rng.randf_range(-0.4, 0.4), 1.0)
		if from_side:
			var left := rng.randf() < 0.5
			pos = Vector2(rect.position.x if left else rect.end.x - 1, rng.randf_range(rect.position.y, rect.end.y))
			direction = Vector2(1.0 if left else -1.0, rng.randf_range(-0.3, 0.6))
		var length := rng.randf_range(0.3, 0.75) * (rect.size.x if from_side else rect.size.y)
		for step in int(length):
			direction = (direction + Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.2, 0.2))).normalized()
			pos += direction
			if not rect.has_point(pos):
				break
			var pixel := Rect2(pos.floor(), Vector2.ONE)
			canvas.draw_rect(pixel, LEAF_DARK if step % 3 else WILT_OLIVE)
			if rng.randf() < 0.05:
				# Ein welkes Blatt seitlich an der Ranke.
				var side := Vector2(-direction.y, direction.x) * (1 if rng.randf() < 0.5 else -1)
				canvas.draw_rect(Rect2((pos + side).floor(), Vector2(2, 2)), WILT_OLIVE)
				canvas.draw_rect(Rect2((pos + side * 2).floor(), Vector2.ONE), LEAF_DARK)
			elif rng.randf() < 0.025:
				canvas.draw_rect(Rect2(pos.floor() + Vector2(1, 0), Vector2(2, 2)), MAGENTA)
