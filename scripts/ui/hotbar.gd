extends VBoxContainer

## Die Hotbar am unteren Bildrand. Sie zeigt die ersten Inventar-Plätze an
## (über ein InventoryGrid) und nimmt die Tasten 1–8 und das Mausrad entgegen.
## Was gewählt ist, merkt sich das Inventar – die Hotbar ist nur das Fenster
## darauf. Läuft auch, wenn das Spiel pausiert, damit man bei offenem
## Inventar-Fenster Items in die Hotbar ziehen kann.
##
## Über der Leiste steht eine Meldungszeile: beim Wechseln der Name des Items
## (sofort), beim Bekommen z. B. "+2 Alraune", und alles, was über Messages
## gemeldet wird. Meldungen warten in einer Schlange, statt sich gegenseitig
## zu überschreiben: Kommen eine Ernte, ein Herbarium-Eintrag und ein
## Stufenaufstieg im selben Moment, sieht man alle drei nacheinander.

# Wie lange eine Meldung steht. Lange Sätze brauchen länger zum Lesen.
const SHOW_TIME_MIN := 1.5
const SHOW_TIME_MAX := 4.0
const SHOW_TIME_PER_CHAR := 0.045
# Wartet schon die nächste, geht es etwas zügiger weiter.
const SHOW_TIME_QUEUED := 1.2
const FADE_TIME := 0.4
# Mehr wartende Meldungen wären nur noch Rauschen; die ältesten fallen weg.
const MAX_QUEUE := 5
# Breiter als die Hotbar, damit lange Meldungen nicht über den Bildrand
# laufen. Was dann noch nicht passt, bricht in eine zweite Zeile um.
const TEXT_WIDTH := 600.0

# Eine Meldung ist ein kleines Dictionary: {"text": …} oder für Items
# {"item": ID, "amount": n}. Item-Meldungen werden erst beim Anzeigen zu
# Text, damit sich gleiche Gewinne zusammenzählen lassen ("+1", "+1" → "+2").
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _show_left := 0.0
var _fade_left := 0.0
# Wie lange die aktuelle Meldung schon steht.
var _shown_for := 0.0

@onready var item_name_label: Label = $ItemName


func _ready() -> void:
	# Fenster mit eigenem Inventar (Brau-Fenster) blenden die Hotbar über
	# diese Gruppe aus.
	add_to_group("hotbar")
	item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name_label.custom_minimum_size.x = TEXT_WIDTH
	item_name_label.modulate.a = 0.0
	# Die Plätze selbst zeichnet das InventoryGrid neu. Hier nur der Text.
	Inventory.selection_changed.connect(_show_item_name)
	Inventory.item_added.connect(_on_item_added)
	Messages.posted.connect(_on_message_posted)


func _process(delta: float) -> void:
	# Im Kampf zeigt die Kampfleiste (CombatBar) Formen und Tränke an der
	# Stelle der Plätze; die Meldungszeile darüber bleibt.
	$Panel.visible = not _in_combat()
	# Während ein Fenster die Hotbar verdeckt oder das Bild schwarz ist, läuft
	# die Zeit für Meldungen nicht: Sonst wären sie vorbei, bevor man sie sieht
	# (z. B. die Mondmeldung, die beim Schlafen im Dunkeln kommt).
	if not is_visible_in_tree() or ScreenFade.is_covering():
		return
	if not _current.is_empty():
		_shown_for += delta
		if _show_left > 0.0:
			_show_left -= delta
			return
		# Wartet schon die nächste, kein langes Ausblenden.
		if _fade_left > 0.0 and _queue.is_empty():
			_fade_left -= delta
			item_name_label.modulate.a = clampf(_fade_left / FADE_TIME, 0.0, 1.0)
			return
		_current = {}
		item_name_label.modulate.a = 0.0
	if not _queue.is_empty():
		_display(_queue.pop_front())


## Name des Items in der Hand: sofort, ohne Warteschlange, denn das ist die
## direkte Antwort auf einen Tastendruck. Wartende Meldungen kommen danach.
func _show_item_name() -> void:
	var item_id := Inventory.selected_item_id()
	if item_id == "":
		return
	# Eine Meldung, die gerade erst erschienen ist, nicht verschlucken: Sie
	# kommt nach dem Namen noch einmal.
	if not _current.is_empty() and not _current.get("selection", false) and _shown_for < 1.0:
		_queue.push_front(_current)
	_display({"text": _with_use_hint(item_id), "selection": true})


func _on_item_added(item_id: String, amount: int) -> void:
	# Gleiches Item kurz hintereinander (Ernte plus Bonus): zusammenzählen.
	if _current.get("item", "") == item_id and _show_left > 0.0:
		_current["amount"] += amount
		_display(_current)
		return
	if not _queue.is_empty() and _queue.back().get("item", "") == item_id:
		_queue.back()["amount"] += amount
		return
	_enqueue({"item": item_id, "amount": amount})


func _on_message_posted(text: String) -> void:
	if text == "":
		return
	# Dieselbe Meldung noch einmal (z. B. mehrfach "Tasche voll"): nur die
	# Zeit verlängern statt sie zu wiederholen.
	if _current.get("text", "") == text and _show_left > 0.0:
		_show_left = _show_time(text)
		return
	for waiting in _queue:
		if waiting.get("text", "") == text:
			return
	_enqueue({"text": text})


func _enqueue(note: Dictionary) -> void:
	_queue.append(note)
	while _queue.size() > MAX_QUEUE:
		_queue.pop_front()


func _display(note: Dictionary) -> void:
	_current = note
	var text := _text_of(note)
	item_name_label.text = text
	item_name_label.custom_minimum_size.x = _balanced_width(text)
	item_name_label.modulate.a = 1.0
	_show_left = _show_time(text)
	_fade_left = FADE_TIME
	_shown_for = 0.0


func _text_of(note: Dictionary) -> String:
	if note.has("item"):
		return "+%d %s" % [note["amount"], Inventory.display_name_for(note["item"])]
	return note.get("text", "")


## Breite, bei der ein langer Text gleich lange Zeilen bekommt, statt einer
## vollen Zeile und einem einzelnen Wort darunter. Sucht die schmalste Breite,
## bei der es nicht mehr Zeilen werden als bei voller Breite.
func _balanced_width(text: String) -> float:
	var font := item_name_label.get_theme_font("font")
	var font_size := item_name_label.get_theme_font_size("font_size")
	var lines := func(width: float) -> int:
		var height := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
		return roundi(height / font.get_height(font_size))
	var target: int = lines.call(TEXT_WIDTH)
	if target <= 1:
		return TEXT_WIDTH
	var low := TEXT_WIDTH / target
	var high := TEXT_WIDTH
	while high - low > 4.0:
		var middle := (low + high) / 2.0
		if lines.call(middle) > target:
			low = middle
		else:
			high = middle
	return ceilf(high)


func _show_time(text: String) -> float:
	var seconds := clampf(SHOW_TIME_MIN + maxf(text.length() - 24, 0) * SHOW_TIME_PER_CHAR, SHOW_TIME_MIN, SHOW_TIME_MAX)
	return minf(seconds, SHOW_TIME_QUEUED) if not _queue.is_empty() else seconds


## Name plus kurzer Hinweis, wie man das Item benutzt, z. B.
## "Irrlicht  ·  Q trinken". Steht nur bei Items, bei denen man es sonst
## nicht erraten würde (Trinken geht über eine eigene Taste).
func _with_use_hint(item_id: String) -> String:
	var item_name := Inventory.display_name_for(item_id)
	var item := ItemData.from_id(item_id)
	if item and item.use == ItemData.Use.DRINK:
		return "%s  ·  %s" % [item_name, tr("HINT_USE_DRINK") % InputHints.key_for("use_item")]
	return item_name


func _unhandled_input(event: InputEvent) -> void:
	# Im Kampfmodus gehören 1–4 und das Mausrad den Digitalis-Formen (Combat).
	if _in_combat():
		return
	if event.is_action_pressed("hotbar_next"):
		Inventory.selected_slot += 1
	elif event.is_action_pressed("hotbar_previous"):
		Inventory.selected_slot -= 1
	else:
		var slot := _pressed_slot_key(event)
		if slot == -1:
			return
		Inventory.selected_slot = slot
	# Verhindert, dass dieselbe Eingabe noch woanders etwas auslöst.
	get_viewport().set_input_as_handled()


func _in_combat() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.combat_mode


## Welche der Tasten 1–8 gedrückt wurde (als Platz 0–7), sonst -1.
func _pressed_slot_key(event: InputEvent) -> int:
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			return i
	return -1
