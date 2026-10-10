class_name PlayerSounds
extends Node

## Die Geräusche der Hexe selbst: Schritte passend zum Boden, Schweben und die
## Aktionen (Schnippen, Ernten, Trinken). Der Klang hängt an den Animationen,
## nicht am Code der einzelnen Aktionen. So klingt z. B. Ernten gleich, egal ob
## sie eine Pflanze, ein Sammelobjekt oder Unkraut herauszieht.
##
## Was danach passiert (Beet erwacht, Item landet in der Tasche), vertont der
## Code, der es auslöst.

# Aktion -> [Frame (ab 0), Sound]. Frames siehe docs/ASSETS.md, "Aktionen der Hexe".
const ACTION_SOUNDS := {
	"snap": [1, "player/snap"],
	"harvest": [2, "garden/harvest"],
	"drink": [1, "brewing/drink"],
}
# Kontakt-Frames der Laufanimation: Hier setzt ein Fuß auf.
const STEP_FRAMES: Array[int] = [0, 4]
# Schneller hintereinander klingt kein Schritt (z. B. wenn beim Richtungswechsel
# die neue Laufanimation gleich mit einem Kontakt-Frame beginnt).
const MIN_STEP_GAP := 0.18
const MIN_FLOAT_START_GAP := 0.5
const FLOAT_FADE := 0.25
const FLOAT_SILENT_DB := -40.0

var _last_step := -1.0
var _last_float_start := -1.0
var _was_walking := false
var _float_player: AudioStreamPlayer
var _float_tween: Tween

# Wird in Player._ready angehängt; dann sind dessen @onready-Variablen schon gesetzt.
@onready var player: Player = get_parent()


func _ready() -> void:
	player.animated_sprite.frame_changed.connect(_on_frame_changed)
	player.animated_sprite.animation_changed.connect(_on_animation_changed)
	player.float_changed.connect(_on_float_changed)
	_float_player = AudioStreamPlayer.new()
	_float_player.bus = &"SFX"
	_float_player.stream = Sfx.get_loop("player/float_loop")
	_float_player.volume_db = FLOAT_SILENT_DB
	add_child(_float_player)


func _on_frame_changed() -> void:
	var sprite := player.animated_sprite
	var kind := String(sprite.animation).get_slice("_", 0)
	if kind == "walk":
		if sprite.frame in STEP_FRAMES:
			_step()
	elif ACTION_SOUNDS.has(kind) and sprite.frame == ACTION_SOUNDS[kind][0]:
		Sfx.play(ACTION_SOUNDS[kind][1])


# Der erste Schritt soll sofort klingen, nicht erst beim nächsten Kontakt-Frame.
func _on_animation_changed() -> void:
	var walking := String(player.animated_sprite.animation).begins_with("walk_")
	if walking and not _was_walking:
		_step()
	_was_walking = walking


func _step() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_step < MIN_STEP_GAP:
		return
	_last_step = now
	var level := get_tree().get_first_node_in_group("level") as Level
	var surface := level.step_surface_at(player.global_position) if level else "soil"
	# Ohne Nummer: Sfx wählt eine der 4 Varianten.
	Sfx.play("player/step_" + surface)


func _on_float_changed(floating: bool) -> void:
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	if floating:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_float_start > MIN_FLOAT_START_GAP:
			Sfx.play("player/float_start")
		_last_float_start = now
		if not _float_player.playing:
			_float_player.play()
		_float_tween.tween_property(_float_player, "volume_db", 0.0, FLOAT_FADE)
	else:
		_float_tween.tween_property(_float_player, "volume_db", FLOAT_SILENT_DB, FLOAT_FADE)
		_float_tween.tween_callback(_float_player.stop)
