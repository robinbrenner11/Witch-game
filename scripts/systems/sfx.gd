extends Node

## Soundeffekte. Läuft als Autoload, damit jedes Script einfach
## `Sfx.play("ui/click")` oder `Sfx.play_at("garden/harvest", global_position)`
## aufrufen kann, ohne eigene Player-Nodes anzulegen.
##
## Die IDs sind Pfade unter assets/audio/sfx/ ohne Endung. Gibt es Varianten
## (`harvest_1.wav`, `harvest_2.wav` …), reicht die ID ohne Nummer: Sfx wählt
## zufällig eine, aber nie zweimal hintereinander dieselbe. Dazu streut die
## Tonhöhe leicht, damit Wiederholungen (Schritte!) nicht nerven.
##
## Busse (default_bus_layout.tres): Music, SFX, Ambience. Alle laufen in Master,
## dessen Lautstärke die Einstellungen steuern.

const BASE_PATH := "res://assets/audio/sfx/"
const MAX_VARIANTS := 8
# Tonhöhen-Streuung: 0.04 = bis zu ±4 %.
const PITCH_SPREAD := 0.04
# Wie viele nicht-räumliche Effekte gleichzeitig klingen dürfen.
const POOL_SIZE := 12

# ID -> Array[AudioStream] (die gefundenen Varianten). Wird beim ersten
# Abspielen gefüllt, danach kommt alles aus dem Speicher.
var _cache: Dictionary = {}
# ID -> zuletzt gespielte Variante, damit sie sich nicht direkt wiederholt.
var _last_variant: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# Effekte (z. B. UI-Klicks im Pausemenü) sollen auch bei Pause klingen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_pool.append(player)


## Spielt einen Effekt ohne Position (UI, Hexe selbst, Meldungen).
func play(id: String, volume_db: float = 0.0, pitch_spread: float = PITCH_SPREAD) -> void:
	var stream := _pick(id)
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	player.play()


## Spielt einen Effekt an einer Stelle in der Welt. Er wird leiser, je weiter
## die Kamera weg ist, und kommt von links/rechts.
func play_at(id: String, world_position: Vector2, volume_db: float = 0.0,
		pitch_spread: float = PITCH_SPREAD) -> void:
	var stream := _pick(id)
	if stream == null:
		return
	# Ein AudioStreamPlayer2D unter diesem Autoload: Da der Autoload keine
	# eigene Position hat, ist global_position einfach die Weltposition.
	var player := AudioStreamPlayer2D.new()
	player.bus = &"SFX"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	player.max_distance = 420.0
	player.attenuation = 1.6
	add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()


## Liefert einen Loop-Stream (z. B. "brewing/cauldron_loop") für einen eigenen
## AudioStreamPlayer2D in einer Szene. Die WAV-Datei wird dabei auf
## nahtloses Wiederholen gestellt, egal wie sie importiert wurde.
func get_loop(id: String) -> AudioStream:
	var stream := _pick(id)
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream.duplicate()
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
		return wav
	return stream


func _pick(id: String) -> AudioStream:
	if not _cache.has(id):
		_cache[id] = _find_variants(id)
	var variants: Array = _cache[id]
	if variants.is_empty():
		push_warning("Sfx: kein Sound für '%s'" % id)
		return null
	if variants.size() == 1:
		return variants[0]
	var index := randi() % variants.size()
	if index == _last_variant.get(id, -1):
		index = (index + 1) % variants.size()
	_last_variant[id] = index
	return variants[index]


# Sucht erst die Datei genau unter der ID, sonst ID_1, ID_2 … bis eine fehlt.
# ResourceLoader.exists funktioniert auch im exportierten Spiel (dort liegen
# nur die importierten Dateien, DirAccess würde die .wav nicht finden).
func _find_variants(id: String) -> Array:
	var found: Array = []
	var exact := BASE_PATH + id + ".wav"
	if ResourceLoader.exists(exact):
		found.append(load(exact))
		return found
	for i in range(1, MAX_VARIANTS + 1):
		var path := "%s%s_%d.wav" % [BASE_PATH, id, i]
		if not ResourceLoader.exists(path):
			break
		found.append(load(path))
	return found


# Nimmt einen freien Player; sind alle belegt, den, der am längsten läuft.
func _free_player() -> AudioStreamPlayer:
	var oldest := _pool[0]
	for player in _pool:
		if not player.playing:
			return player
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest
