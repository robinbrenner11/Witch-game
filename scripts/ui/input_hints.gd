class_name InputHints
extends RefCounted

## Liest aus der Tastenbelegung (Projekt → Eingabe-Zuordnung), wie eine
## Aktion gerade ausgelöst wird, z. B. "E" für interact oder "Q / Rechtsklick"
## für use_item. So stehen Tasten nie fest im Text: Ändert sich die Belegung
## (später vielleicht im Einstellungsmenü), stimmen alle Hinweise von selbst.
##
## Nur statische Funktionen, deshalb kein Autoload: InputHints.key_for("interact").

# Schlüssel in data/translations/texts.csv für Maustasten.
const MOUSE_KEYS := {
	MOUSE_BUTTON_LEFT: "KEY_MOUSE_LEFT",
	MOUSE_BUTTON_RIGHT: "KEY_MOUSE_RIGHT",
	MOUSE_BUTTON_MIDDLE: "KEY_MOUSE_MIDDLE",
	MOUSE_BUTTON_WHEEL_UP: "KEY_MOUSE_WHEEL",
	MOUSE_BUTTON_WHEEL_DOWN: "KEY_MOUSE_WHEEL",
}
# Kürzere Namen, damit die Hinweise klein bleiben.
const SHORT_NAMES := {"Escape": "Esc"}


## Erste Taste der Aktion als kurzer Text, z. B. "E". Leer, wenn keine belegt ist.
static func key_for(action: String) -> String:
	var keys := keys_for(action)
	return keys[0] if not keys.is_empty() else ""


## Alle Tasten der Aktion, z. B. ["Q", "Rechtsklick"].
static func keys_for(action: String) -> Array[String]:
	var result: Array[String] = []
	if not InputMap.has_action(action):
		return result
	for event in InputMap.action_get_events(action):
		var label := _label_of(event)
		if label != "" and not result.has(label):
			result.append(label)
	return result


static func _label_of(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		# physical_keycode ist die Lage auf der Tastatur (WASD bleibt WASD, auch
		# auf AZERTY). Für die Anzeige zählt, was auf der Taste steht.
		var keycode := key.keycode
		if key.physical_keycode != KEY_NONE:
			keycode = key.physical_keycode
			# Ohne Bildschirm (Headless-Tests) gibt es kein Tastaturlayout.
			if DisplayServer.get_name() != "headless":
				keycode = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
		var text := OS.get_keycode_string(keycode)
		return SHORT_NAMES.get(text, text)
	if event is InputEventMouseButton:
		var button := (event as InputEventMouseButton).button_index
		return TranslationServer.translate(MOUSE_KEYS.get(button, ""))
	return ""
