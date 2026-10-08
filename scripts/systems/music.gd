extends Node

## Hintergrundmusik. Läuft als Autoload, damit sie über Szenenwechsel (Titel,
## Spiel, Orte) hinweg einfach weiterspielt, auch in der Pause.
##
## Gerade ein Loop ("Mondgarten") in zwei Fassungen: normal und mit Summen für
## Vollmondnächte. Beim Wechsel blendet die eine weich in die andere über, an
## derselben Stelle im Takt. Später, mit einzelnen Spuren aus der DAW, können
## daraus Ebenen werden (z. B. Beat aus im Unterschlupf), siehe
## docs/audio/garten_loop/LIESMICH.md.

const NORMAL := "res://assets/audio/music/mondgarten.ogg"
const FULL_MOON := "res://assets/audio/music/mondgarten_vollmond.ogg"
const CROSSFADE_TIME := 4.0
# Stumm in Dezibel. -80 dB ist für das Ohr nichts mehr.
const SILENT_DB := -80.0

var _normal_player: AudioStreamPlayer
var _full_moon_player: AudioStreamPlayer
var _full_moon_active := false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_normal_player = _make_player(NORMAL)
	_full_moon_player = _make_player(FULL_MOON)
	_full_moon_player.volume_db = SILENT_DB
	# Beide laufen immer gleichzeitig mit; hörbar ist nur eine. So passen sie
	# beim Überblenden genau zusammen.
	_normal_player.play()
	_full_moon_player.play()


# Jeden Frame nachsehen ist billig und deckt alles ab: neue Nacht, geladener
# Spielstand, neues Spiel.
func _process(_delta: float) -> void:
	if Moon.is_full() != _full_moon_active:
		_crossfade(Moon.is_full())


func _crossfade(full_moon: bool) -> void:
	_full_moon_active = full_moon
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_full_moon_player, "volume_db", 0.0 if full_moon else SILENT_DB, CROSSFADE_TIME)
	_tween.tween_property(_normal_player, "volume_db", SILENT_DB if full_moon else 0.0, CROSSFADE_TIME)


# Beim Beenden die Wiedergabe stoppen. (Godot meldet trotzdem, dass die
# Musik beim Beenden noch in Gebrauch war; das ist harmlos.)
func _exit_tree() -> void:
	for player in [_normal_player, _full_moon_player]:
		player.stop()
		player.stream = null


func _make_player(path: String) -> AudioStreamPlayer:
	var stream: AudioStreamOggVorbis = load(path)
	# Nahtlos wiederholen; der Loop ist dafür gebaut.
	stream.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player
