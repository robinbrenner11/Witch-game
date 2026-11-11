class_name Plant
extends Node2D

## Zeigt eine Pflanze im Beet an. Ihr Zustand (Art, Stufe) liegt im Autoload
## Garden – das Beet setzt data und growth_stage von dort aus. Ob und wann sie
## wächst, entscheidet Garden.

# Welche Art hier wächst. Muss gesetzt sein, bevor die Pflanze in den
# Szenenbaum kommt (macht das Beet).
@export var data: PlantData

const WILT_MATERIAL := preload("res://assets/effects/shaders/wilt_material.tres")

# Ein Setter: läuft bei jeder Zuweisung, so passt das Bild immer zur Stufe.
var growth_stage: int = 0:
	set(value):
		growth_stage = value
		if is_node_ready():
			_update_sprite()

# Unter einer hemmenden Aura (Nachtschatten): entsättigt und kühl-dunkel.
# Alle welken Pflanzen teilen sich ein Material, das ist billiger als eins
# pro Pflanze.
var wilted: bool = false:
	set(value):
		wilted = value
		if is_node_ready():
			sprite.material = WILT_MATERIAL if wilted else null

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: NightLight = $Glow
@onready var shadow: Sprite2D = $Shadow

# Kleines Funkeln über reifen Pflanzen, damit man auf Abstand sieht, welches
# Beet erntereif ist (nicht jede Pflanze leuchtet von selbst).
var _sparkle: RipeSparkle


func _ready() -> void:
	# Das Spritesheet enthält alle Stufen nebeneinander; hframes teilt es
	# in gleich breite Bilder, frame wählt eins davon aus.
	sprite.texture = data.stages_texture
	sprite.hframes = data.stage_count
	glow.texture = data.glow_texture
	glow.color = data.glow_color
	glow.base_energy = data.glow_energy
	glow.position = data.glow_offset
	_sparkle = RipeSparkle.new()
	add_child(_sparkle)
	_update_sprite()
	sprite.material = WILT_MATERIAL if wilted else null


func is_ripe() -> bool:
	return growth_stage >= data.stage_count - 1


func _update_sprite() -> void:
	sprite.frame = growth_stage
	# Ein Samen in der Erde wirft noch keinen Schatten.
	shadow.visible = growth_stage > 0
	# Erst reife Pflanzen leuchten – so wird das Reifwerden nachts sichtbar.
	glow.enabled = is_ripe() and data.glow_texture != null
	_sparkle.active = is_ripe()


## Ab und zu ein goldener Lichtpunkt über der reifen Pflanze, an wechselnder
## Stelle: aufblitzen, kurz als Kreuz, wieder verglimmen. Die Pausen sind
## zufällig, damit ein volles Beet nicht im Takt blinkt.
## (Platzhalter-Zeichnung, bis es eine Grafik gibt.)
class RipeSparkle:
	extends Node2D

	const GOLD := Color("#D9A441")
	const BONE := Color("#EADFCB")
	# Drei Bilder: Punkt, Kreuz, Punkt.
	const FRAME_TIME := 0.12
	const PAUSE_MIN := 1.6
	const PAUSE_MAX := 3.4

	var active := false:
		set(value):
			active = value
			visible = value
	var _wait := 0.0
	var _frame := -1
	var _frame_left := 0.0
	var _spot := Vector2.ZERO

	func _ready() -> void:
		visible = active
		z_index = 2
		# Unbeleuchtet: Das Funkeln ist auch in tiefer Nacht zu sehen.
		var unshaded := CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = unshaded
		_wait = randf_range(0.2, PAUSE_MAX)

	func is_sparkling() -> bool:
		return _frame >= 0

	func _process(delta: float) -> void:
		if not active:
			return
		if _frame < 0:
			_wait -= delta
			if _wait <= 0.0:
				_frame = 0
				_frame_left = FRAME_TIME
				_spot = Vector2(randi_range(-6, 6), randi_range(-24, -12))
				queue_redraw()
			return
		_frame_left -= delta
		if _frame_left <= 0.0:
			_frame += 1
			_frame_left = FRAME_TIME
			if _frame > 2:
				_frame = -1
				_wait = randf_range(PAUSE_MIN, PAUSE_MAX)
			queue_redraw()

	func _draw() -> void:
		if _frame < 0:
			return
		draw_rect(Rect2(_spot, Vector2.ONE), BONE)
		if _frame == 1:
			for arm: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_rect(Rect2(_spot + arm, Vector2.ONE), GOLD)
