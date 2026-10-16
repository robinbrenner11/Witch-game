class_name RequestData
extends Resource

## Ein Gesuch am Anschlagbrett: ein Zettel von jemandem aus dem Dorf, der
## etwas braucht. Die Dorfbewohner sieht man nicht (sie schlafen nachts),
## sie schreiben. Jedes Gesuch ist eine Datei in data/requests/, neuer Inhalt
## braucht also keinen Code. Siehe docs/design/welt_und_items.md, Abschnitt 7.

## Eindeutige ID, gleich dem Dateinamen.
@export var id: String = ""
## Wer den Zettel schreibt (kurze ID, z. B. "carpenter"). Von jeder Person
## hängt höchstens ein Zettel gleichzeitig.
@export var giver: String = ""
## Text-Schlüssel des Zettels (höchstens zwei Zeilen, Unterschrift am Ende).
@export var text_key: String = ""
## Text-Schlüssel des Danks beim Abgeben.
@export var thanks_key: String = ""
@export var item_id: String = ""
@export var amount: int = 1
## Belohnungen. ITEM, RECIPE und XP wie im Grimoire; STAT "chest_capacity"
## vergrößert die Truhe um value Plätze.
@export var rewards: Array[RewardData] = []
## Gerücht als Belohnung: verrät im Grimoire eine Zutat dieses Rezepts.
@export var hint_recipe: String = ""
@export var hint_ingredient: String = ""

@export_group("Wann")
## Frühestens ab dieser Nacht.
@export var min_day: int = 1
## Nur in diesen Mondphasen (Moon.Phase) wird der Zettel aufgehängt. Leer = immer.
@export var moon_phases: Array[int] = []
@export var requires_flags: Array[String] = []
@export var blocked_by_flags: Array[String] = []
## Darf nach dem Abgeben wiederkommen.
@export var repeatable: bool = false
## Wird beim Abgeben gesetzt (für Ketten: das nächste Gesuch braucht es).
@export var sets_flag: String = ""
## Wie oft er im Vergleich zu anderen gezogen wird.
@export var weight: int = 1


## Darf dieser Zettel heute Nacht neu aufgehängt werden?
func can_post(day: int, phase: int, done_count: int) -> bool:
	if day < min_day:
		return false
	if done_count > 0 and not repeatable:
		return false
	if not moon_phases.is_empty() and phase not in moon_phases:
		return false
	return WorldState.has_all(requires_flags) and WorldState.has_none(blocked_by_flags)
