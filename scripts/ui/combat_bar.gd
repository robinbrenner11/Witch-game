extends Control

## Kampfleiste: steht im Kampfmodus an der Stelle der Hotbar-Plätze (die
## Meldungszeile darüber bleibt). Links die bekannten Digitalis-Formen mit
## ihren Tasten (1, 2 …), die gewählte im goldenen Rahmen. Rechts der
## Trank-Schnellzugriff: Icon und Anzahl des gewählten Kampftranks, Q zum
## Benutzen und, wenn es mehrere Sorten gibt, R zum Wechseln mit kleinen
## Punkten für jede Sorte.
##
## Zeichnet alles selbst (wie die Lebensleiste) und liest jeden Frame nur ab,
## was Combat und CombatPotions gerade wissen; hier wird nichts entschieden.
## Die Hotbar blendet sie ein und aus (hotbar.gd).

const FRAME := preload("res://assets/ui/hotbar_slot.png")
const FRAME_SELECTED := preload("res://assets/ui/hotbar_slot_selected.png")
const PANEL := preload("res://assets/ui/hotbar_panel.png")
const FONT := preload("res://assets/ui/fonts/game_font.tres")
const DIGITS := preload("res://assets/ui/hotbar_digits.fnt")

# Maße wie bei der Hotbar: 40er-Plätze (Grafik 2× vorskaliert), 2 px Abstand,
# 4 px Rand im Panel. Zwischen Formen und Trank etwas mehr Luft.
const SLOT := 40
const SLOT_GAP := 2
const GROUP_GAP := 10
const MARGIN := 4
const ICON_INSET := 4
const ICON_SIZE := 32

const KEY_COLOR := Color("#D9A441")
const PLATE_COLOR := Color(0.0549, 0.0392, 0.0784, 0.82)
const COUNT_COLOR := Color("#EADFCB")
const PIP_COLOR := Color("#D9A441")
const PIP_DIM := Color("#4D2A57")
const FONT_SIZE := 16

var _panel_style: StyleBoxTexture
var _player: Player
var _combat: Combat
var _potions: CombatPotions


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_style = StyleBoxTexture.new()
	_panel_style.texture = PANEL
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_panel_style.set_texture_margin(side, 6.0)
	custom_minimum_size = _bar_size(2)


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _combat == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
		_combat = _player.get_node("Combat")
		_potions = _player.get_node("CombatPotions")
	var wanted := _bar_size(_combat.known_forms().size())
	if custom_minimum_size != wanted:
		custom_minimum_size = wanted
	queue_redraw()


func _bar_size(form_count: int) -> Vector2:
	var forms := maxi(form_count, 1)
	var width := MARGIN * 2 + forms * SLOT + (forms - 1) * SLOT_GAP + GROUP_GAP + SLOT
	return Vector2(width, MARGIN * 2 + SLOT)


func _draw() -> void:
	if _combat == null:
		return
	draw_style_box(_panel_style, Rect2(Vector2.ZERO, size))
	var x := float(MARGIN)
	var forms := _combat.known_forms()
	for i in forms.size():
		var slot := Vector2(x, MARGIN)
		draw_texture(FRAME_SELECTED if i == _combat.form_index else FRAME, slot)
		if forms[i].icon:
			draw_texture_rect(forms[i].icon, Rect2(slot + Vector2.ONE * ICON_INSET, Vector2.ONE * ICON_SIZE), false)
		if i < 4:
			_draw_key(slot + Vector2(2, 2), InputHints.key_for("hotbar_%d" % (i + 1)), 1.0)
		x += SLOT + SLOT_GAP
	x += GROUP_GAP - SLOT_GAP
	_draw_potion_slot(Vector2(x, MARGIN))


func _draw_potion_slot(slot: Vector2) -> void:
	draw_texture(FRAME_SELECTED if _potions.is_aiming() else FRAME, slot)
	var item := ItemData.from_id(_potions.selected_id)
	# Ohne Kampftrank in der Tasche bleibt der Platz leer und Q blass.
	_draw_key(slot + Vector2(2, 2), InputHints.key_for("potion_quick"), 1.0 if item else 0.45)
	if item == null:
		return
	if item.icon:
		draw_texture_rect(item.icon, Rect2(slot + Vector2.ONE * ICON_INSET, Vector2.ONE * ICON_SIZE), false)
	# Anzahl unten rechts wie in der Hotbar (eigene Ziffernschrift).
	var count := str(Inventory.count(item.id))
	var count_width := DIGITS.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(DIGITS, slot + Vector2(SLOT - 4 - count_width, SLOT - 2), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COUNT_COLOR)
	var sorts := _potions.available()
	if sorts.size() <= 1:
		return
	# Mehrere Sorten: R oben rechts, darunter je Sorte ein Punkt.
	var key := InputHints.key_for("potion_next")
	var key_width := FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_draw_key(slot + Vector2(SLOT - 2 - key_width - 4, 2), key, 1.0)
	for i in sorts.size():
		var pip := slot + Vector2(SLOT - 5 - 3 * (sorts.size() - 1 - i), 18)
		draw_rect(Rect2(pip, Vector2(2, 2)), PIP_COLOR if sorts[i] == item.id else PIP_DIM)


## Taste als goldener Buchstabe auf kleiner dunkler Plakette (wie der
## Interaktions-Hinweis), damit sie auch auf hellen Icons lesbar bleibt.
func _draw_key(at: Vector2, key: String, alpha: float) -> void:
	if key == "":
		return
	var width := FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_rect(Rect2(at, Vector2(width + 4, 11)), Color(PLATE_COLOR, PLATE_COLOR.a * alpha))
	draw_string(FONT, at + Vector2(2, 9), key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(KEY_COLOR, alpha))
