extends StaticBody2D

## Das Lesepult im Unterschlupf. Darauf liegt Vesperas Grimoire, bis die
## Hexe es mitnimmt. Danach schlägt E am Pult das Buch auf: Liegen befallene
## Seiten bereit, gleich beim Opfer, sonst normal. Am Pult lassen sich auch
## Hexenpfade wechseln.

const WITH_BOOK := preload("res://assets/environment/props/lectern_book.png")
const EMPTY := preload("res://assets/environment/props/lectern.png")
const MAGIC := Color("#C2307A")
# Das Glimmen atmet langsam (Sekunden pro Atemzug) zwischen diesen Stärken.
const PULSE_TIME := 2.4
const PULSE_MIN := 0.35
const PULSE_MAX := 0.8

var _glow: PointLight2D
var _motes: CPUParticles2D
var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_add_glow()
	Grimoire.changed.connect(_update_look)
	_update_look()


## Solange Vesperas Buch noch auf dem Pult liegt, glimmt es magenta und
## kleine Funken steigen auf. Die Hexe wacht neben der Truhe auf; das Glimmen
## zieht den Blick ohne Text zum Buch, in dem die ersten Ziele stehen.
func _add_glow() -> void:
	_glow = PointLight2D.new()
	_glow.texture = preload("res://assets/effects/lights/light_round_64.png")
	_glow.color = MAGIC
	_glow.texture_scale = 0.8
	_glow.position = Vector2(0, -26)
	add_child(_glow)
	_motes = CPUParticles2D.new()
	_motes.amount = 6
	_motes.lifetime = 1.6
	_motes.position = Vector2(0, -28)
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(5, 1)
	_motes.direction = Vector2.UP
	_motes.spread = 15.0
	_motes.gravity = Vector2(0, -6)
	_motes.initial_velocity_min = 3.0
	_motes.initial_velocity_max = 7.0
	_motes.color = Color("#E458B1")
	# Unbeleuchtet: Die Funken leuchten selbst, auch in tiefer Nacht.
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_motes.material = unshaded
	add_child(_motes)


func _process(delta: float) -> void:
	if not _glow.visible:
		return
	_time += delta
	var wave := (sin(_time * TAU / PULSE_TIME) + 1.0) / 2.0
	_glow.energy = lerpf(PULSE_MIN, PULSE_MAX, wave)


## Glimmt das Pult gerade (Buch liegt noch darauf)?
func is_glowing() -> bool:
	return _glow.visible


## Text für den Interaktions-Hinweis (siehe Interactable).
func interaction_prompt() -> String:
	return "PROMPT_READ" if Grimoire.has_book else "PROMPT_TAKE"


func _on_interactable_interacted(_player: Node2D) -> void:
	if not Grimoire.has_book:
		Grimoire.find_book()
		Sfx.play("world/book_pickup")
		Messages.post(tr("MSG_LECTERN_BOOK"))
	else:
		var book := get_tree().get_first_node_in_group("grimoire_book") as GrimoireBook
		if not Grimoire.blighted_pages().is_empty():
			book.open_offering()
		else:
			book.open("", false, true)


func _update_look() -> void:
	sprite.texture = EMPTY if Grimoire.has_book else WITH_BOOK
	_glow.visible = not Grimoire.has_book
	_motes.emitting = not Grimoire.has_book
