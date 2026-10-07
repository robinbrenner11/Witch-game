extends Node

## Kurze Rückmeldungen an die Spielerin ("Kein Platz mehr in der Tasche").
## Läuft als Autoload, damit jedes Script etwas melden kann, ohne zu wissen,
## wo und wie es angezeigt wird. Angezeigt wird es von der Hotbar, in derselben
## Zeile wie die Item-Namen.
##
## Spieltexte: keine Gedankenstriche, keine deutschen Anführungszeichen, keine
## Auslassungspunkte – die Pixelschrift kennt sie nicht.

signal posted(text: String)


func post(text: String) -> void:
	posted.emit(text)
