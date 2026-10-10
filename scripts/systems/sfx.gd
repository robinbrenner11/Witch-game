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
##
## Außerdem: Jeder Knopf im Spiel (Button, CheckBox …) klickt und raschelt beim
## Drüberfahren von selbst, und die Atmo des Orts läuft hier (set_ambience).

const BASE_PATH := "res://assets/audio/sfx/"
const MAX_VARIANTS := 8
# Tonhöhen-Streuung: 0.04 = bis zu ±4 %.
const PITCH_SPREAD := 0.04
# Wie viele nicht-räumliche Effekte gleichzeitig klingen dürfen.
const POOL_SIZE := 12
# Stumm in Dezibel. -80 dB ist für das Ohr nichts mehr.
const SILENT_DB := -80.0
const AMBIENCE_FADE := 2.5

# ID -> Array[AudioStream] (die gefundenen Varianten). Wird beim ersten
# Abspielen gefüllt, danach kommt alles aus dem Speicher.
var _cache: Dictionary = {}
# ID -> zuletzt gespielte Variante, damit sie sich nicht direkt wiederholt.
var _last_variant: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
# Zwei Player für die Atmo: Beim Ortswechsel blendet der eine aus, der andere ein.
var _ambience_players: Array[AudioStreamPlayer] = []
var _ambience_index := 0
var _ambience_id := ""
var _ambience_tween: Tween


func _ready() -> void:
	# Effekte (z. B. UI-Klicks im Pausemenü) sollen auch bei Pause klingen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_pool.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Ambience"
		player.volume_db = SILENT_DB
		add_child(player)
		_ambience_players.append(player)
	# node_added meldet jeden Node, der irgendwo im Spiel dazukommt. So bekommen
	# alle Knöpfe ihren Klang, ohne dass jedes Menü daran denken muss.
	get_tree().node_added.connect(_on_node_added)


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


## Ein Loop, der an einer Stelle in der Welt läuft (Kessel, Feuer). Als Kind
## des Objekts anhängen: add_child(Sfx.make_loop_player("brewing/cauldron_loop")).
## Er startet von selbst und pausiert mit dem Spiel.
func make_loop_player(id: String, volume_db: float = 0.0, max_distance: float = 300.0) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.bus = &"SFX"
	player.stream = get_loop(id)
	player.volume_db = volume_db
	player.max_distance = max_distance
	player.attenuation = 1.6
	# autoplay startet ihn, sobald er im Szenenbaum ist.
	player.autoplay = true
	return player


## Wechselt die Atmo (Wind, Grillen, Ofen …) weich zu einem anderen Loop.
## "" blendet sie aus (z. B. im Titelbild). Jeder Ort ruft das beim Laden auf.
func set_ambience(id: String) -> void:
	if id == _ambience_id:
		return
	_ambience_id = id
	if _ambience_tween:
		_ambience_tween.kill()
	var old_player := _ambience_players[_ambience_index]
	_ambience_index = 1 - _ambience_index
	var new_player := _ambience_players[_ambience_index]
	_ambience_tween = create_tween().set_parallel()
	_fade(old_player, 0.0)
	if id != "":
		new_player.stream = get_loop(id)
		if new_player.stream:
			new_player.volume_db = SILENT_DB
			# Irgendwo im Loop anfangen, damit nicht jeder Ortswechsel gleich klingt.
			new_player.play(randf() * new_player.stream.get_length())
			_fade(new_player, 1.0)
	_ambience_tween.chain().tween_callback(old_player.stop)


# Blendet in linearer Lautstärke statt in Dezibel: Das klingt gleichmäßig,
# ein Tween direkt auf volume_db wäre lange still und dann plötzlich laut.
func _fade(player: AudioStreamPlayer, to: float) -> void:
	var from := db_to_linear(player.volume_db)
	_ambience_tween.tween_method(func(v: float) -> void:
		player.volume_db = linear_to_db(maxf(v, 0.0001)), from, to, AMBIENCE_FADE)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.pressed.connect(play.bind("ui/click", 0.0, PITCH_SPREAD))
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				play("ui/hover"))


# Beim Beenden die Wiedergabe stoppen, sonst meldet Godot die Streams als
# noch in Gebrauch (harmlos, aber so bleibt die Ausgabe sauber).
func _exit_tree() -> void:
	for player in _pool + _ambience_players:
		player.stop()
		player.stream = null


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
