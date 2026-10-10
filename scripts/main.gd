extends Node

## Hält alles zusammen, was über Ortswechsel hinweg bestehen bleibt: die Hexe,
## die UI und die Nachtfärbung. Darunter hängt immer genau ein Ort (Level).
## Die Hexe wandert beim Wechsel in den neuen Ort mit, deshalb bleiben z. B.
## ein getrunkenes Irrlicht oder offene Fenster erhalten.
##
## Beim Spielstart wacht die Hexe am Bett auf (im Unterschlupf).

# Hier steht das Bett, an dem die Hexe beim Spielstart aufwacht.
const START_LEVEL := "res://scenes/world/shelter.tscn"

var level: Level
var _travelling := false

@onready var player: Player = $Player


func _ready() -> void:
	add_to_group("main")
	_load_level(START_LEVEL)
	var bed := get_tree().get_first_node_in_group("bed")
	if bed:
		player.global_position = bed.wake_spot.global_position
	player.camera.reset_smoothing()


## Wechsel in einen anderen Ort: abblenden, Ort tauschen, Hexe an den
## Zielausgang setzen, aufblenden. Ausgänge rufen das über die Gruppe "main".
func travel(scene_path: String, exit_name: String) -> void:
	if _travelling:
		return
	_travelling = true
	player.set_controls_enabled(false)
	Sfx.play("world/travel")
	await ScreenFade.fade_out()
	_load_level(scene_path)
	var exit := level.find_exit(exit_name)
	if exit:
		player.global_position = exit.spawn_position()
	else:
		push_warning("Ausgang %s gibt es in %s nicht" % [exit_name, scene_path])
	player.camera.reset_smoothing()
	await ScreenFade.fade_in()
	player.set_controls_enabled(true)
	_travelling = false


func _load_level(scene_path: String) -> void:
	if level:
		# Die Hexe erst herausnehmen, sonst würde sie mit dem alten Ort gelöscht.
		player.reparent(self)
		remove_child(level)
		level.queue_free()
	level = load(scene_path).instantiate()
	add_child(level)
	# Ein neuer Ort zählt fürs Grimoire (Wildcraft), aber nur beim ersten Mal viel.
	Grimoire.report("visit", {"id": level.name})
	# Ganz nach vorn in der Reihenfolge, damit der Ort unter der UI liegt.
	move_child(level, 0)
	# In Objects, damit die Y-Sortierung die Hexe vor oder hinter Dinge stellt.
	player.reparent(level.objects)
	level.apply_camera_limits(player.camera)
