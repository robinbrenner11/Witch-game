class_name Digitalis
extends Node2D

## Digitalis, der Fingerhut-Stab, so wie die Hexe ihn im Kampf neben sich
## führt. Zeigt nur an: Combat entscheidet, wo er steht, welche Form er hat
## und wann er zuschlägt. Der Ursprung ist der Fuß des Stabs. Grafik und Maße:
## docs/ASSETS.md, Abschnitt Digitalis. Die Sichel ist eine Platzhalter-
## Zeichnung (SickleShape), bis es eine Grafik gibt.

const IDLE := preload("res://assets/items/digitalis/digitalis_idle.png")
const IDLE_GLOW := preload("res://assets/items/digitalis/digitalis_idle_glow.png")
const ATTACK := preload("res://assets/items/digitalis/digitalis_attack.png")
const ATTACK_GLOW := preload("res://assets/items/digitalis/digitalis_attack_glow.png")
const LIGHT_TEXTURE := preload("res://assets/effects/lights/light_round_64.png")

const FRAME_COUNT := 4
const IDLE_FPS := 4.0
const ATTACK_FPS := 12.0
# Der Fuß liegt im Frame (24×60) zwischen Spalte 10 und 11 an der Unterkante.
# Ohne centered rückt dieser Versatz ihn genau auf den Ursprung.
const FRAME_OFFSET := Vector2(-11, -60)
# Die glimmende Knospe an der Spitze, relativ zum Fuß (nicht gespiegelt).
const TIP := Vector2(5, -50)
const LIGHT_COLOR := Color(0.89, 0.35, 0.69)
const LIGHT_RADIUS := 24.0
# Lichtstärke je Idle-Frame, passend zum Puls der Spitze (0-1-2-1).
const IDLE_ENERGY: Array[float] = [0.5, 0.58, 0.65, 0.58]
const ATTACK_ENERGY := 1.2

# Wie stark die Spitze beim Ausholen zusätzlich leuchtet.
const CHARGE_ENERGY := 2.2
const SICKLE_TIP := Vector2(6, -46)

var form_id := "staff"

var _sprite: AnimatedSprite2D
var _glow: AnimatedSprite2D
var _light: NightLight
var _sickle: SickleShape
# Ausholen: läuft von 0 bis charge_time hoch, 0 = lädt nicht.
var _charge := 0.0
var _charge_time := 0.0


func _ready() -> void:
	_sprite = _add_layer(false)
	_glow = _add_layer(true)
	_light = NightLight.new()
	_light.texture = LIGHT_TEXTURE
	_light.texture_scale = LIGHT_RADIUS * 2.0 / LIGHT_TEXTURE.get_width()
	_light.color = LIGHT_COLOR
	_light.position = TIP
	add_child(_light)
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sickle = SickleShape.new()
	add_child(_sickle)
	_play(&"idle")
	set_form(form_id)


func _process(delta: float) -> void:
	if _charge_time > 0.0:
		_charge = minf(_charge + delta, _charge_time)
		# Spitze bzw. Klinge glüht beim Ausholen immer heller.
		_light.base_energy = lerpf(IDLE_ENERGY[0], CHARGE_ENERGY, _charge / _charge_time)
	_sickle.flash = maxf(_sickle.flash - delta, 0.0)
	_sickle.charge = _charge / _charge_time if _charge_time > 0.0 else 0.0
	_sickle.queue_redraw()


## Verwandelt Digitalis in eine andere Form. Bekannt sind "staff" (Grafik)
## und "sickle" (Platzhalter); unbekannte Formen zeigen vorerst den Stab.
func set_form(new_form: String) -> void:
	form_id = new_form
	var is_sickle := form_id == "sickle"
	_sprite.visible = not is_sickle
	_glow.visible = not is_sickle
	_sickle.visible = is_sickle
	_light.position = SICKLE_TIP if is_sickle else TIP


## Ausholen für einen starken Angriff: leuchtet in seconds Sekunden hoch.
## Endet mit attack() oder stop_charge() (z. B. wenn die Hexe ausweicht).
func charge(seconds: float) -> void:
	_charge = 0.0
	_charge_time = maxf(seconds, 0.01)


func stop_charge() -> void:
	_charge = 0.0
	_charge_time = 0.0
	_on_frame_changed()


## Blick nach links: Stab spiegeln, damit die Glocken nach vorne zeigen.
## Gespiegelt wird der ganze Node um den Fuß, so wandern Spitze und Licht mit.
func set_flipped(flipped: bool) -> void:
	scale.x = -1.0 if flipped else 1.0


## Die Spitze in Weltkoordinaten, dort starten die Zauber.
func tip_position() -> Vector2:
	return to_global(SICKLE_TIP if form_id == "sickle" else TIP)


## Ein Angriff: Die Traube glüht einmal auf (Sichel: die Klinge blitzt),
## danach wieder Idle.
func attack() -> void:
	_charge_time = 0.0
	_charge = 0.0
	_sickle.flash = 0.15
	_play(&"attack")


func _play(animation: StringName) -> void:
	_sprite.play(animation)
	_glow.play(animation)
	# Beide Ebenen starten im selben Frame, sonst läuft das Leuchten daneben her.
	_glow.frame = _sprite.frame
	_on_frame_changed()


func _on_frame_changed() -> void:
	_glow.frame = _sprite.frame
	if _charge_time > 0.0:
		return
	if _sprite.animation == &"attack":
		_light.base_energy = ATTACK_ENERGY
	else:
		_light.base_energy = IDLE_ENERGY[_sprite.frame]


func _on_animation_finished() -> void:
	if _sprite.animation == &"attack":
		_play(&"idle")


func _add_layer(glow: bool) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", IDLE_GLOW if glow else IDLE, IDLE_FPS, true)
	_add_strip(frames, &"attack", ATTACK_GLOW if glow else ATTACK, ATTACK_FPS, false)
	var animated := AnimatedSprite2D.new()
	animated.sprite_frames = frames
	animated.centered = false
	animated.offset = FRAME_OFFSET
	if glow:
		# Die Leucht-Ebene ignoriert die Nachtfärbung, wie bei Pilzen und Tränken.
		var material := CanvasItemMaterial.new()
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		animated.material = material
	add_child(animated)
	return animated


func _add_strip(frames: SpriteFrames, animation: StringName, strip: Texture2D, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	var frame_size := Vector2(strip.get_width() / float(FRAME_COUNT), strip.get_height())
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame(animation, atlas)


## Platzhalter für die Sichel-Form, gleiche Fußhöhe wie der Stab: dunkler
## Stängel, Goldgriff mit Wicklung, oben eine helle Klinge als Sichelmond mit
## Magenta-Schneide. Licht von oben links. Blitzt beim Hieb, glüht beim Ausholen.
class SickleShape:
	extends Node2D

	const STEM := Color("#2B1633")
	const STEM_LIGHT := Color("#4D2A57")
	const GOLD := Color("#D9A441")
	const GOLD_DARK := Color("#9C6834")
	const BLADE := Color("#EADFCB")
	const BLADE_SHADE := Color("#C6B8BE")
	const EDGE := Color("#E458B1")

	var flash := 0.0
	var charge := 0.0

	func _ready() -> void:
		# Die Schneide leuchtet durch die Nacht wie die Spitze des Stabs.
		material = CombatFx.unshaded()

	func _draw() -> void:
		# Stängel, 2 px breit, links etwas heller.
		draw_rect(Rect2(-1, -44, 2, 42), STEM)
		draw_rect(Rect2(-1, -44, 1, 42), STEM_LIGHT)
		# Goldgriff mit Wicklung auf Handhöhe.
		draw_rect(Rect2(-2, -24, 4, 8), GOLD_DARK)
		draw_rect(Rect2(-2, -24, 2, 8), GOLD)
		for y in [-23, -20, -17]:
			draw_rect(Rect2(-2, y, 4, 1), GOLD_DARK)
		# Klinge: Sichelmond nach vorne (rechts), oben am Stängel.
		var blade := BLADE.lerp(Color.WHITE, minf(flash * 6.0, 1.0))
		draw_arc(Vector2(6, -44), 8.0, PI * 1.05, PI * 2.1, 10, BLADE_SHADE, 3.0)
		draw_arc(Vector2(6, -45), 8.0, PI * 1.05, PI * 2.1, 10, blade, 2.0)
		var edge := EDGE.lerp(Color("#FFD2EC"), charge)
		draw_arc(Vector2(6, -44), 10.0, PI * 1.1, PI * 2.0, 10, Color(edge, 0.6 + 0.4 * charge), 1.0)
		# Kragen mit Magenta-Stein wie beim Stab.
		draw_rect(Rect2(-2, -45, 4, 2), GOLD)
		draw_rect(Rect2(-1, -45, 2, 1), EDGE)
