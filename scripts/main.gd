extends Node

## Hält alles zusammen, was über Ortswechsel hinweg bestehen bleibt: die Hexe,
## die UI und die Nachtfärbung. Darunter hängt immer genau ein Ort (Level).
## Die Hexe wandert beim Wechsel in den neuen Ort mit, deshalb bleiben z. B.
## ein getrunkenes Irrlicht oder offene Fenster erhalten.
##
## Beim Spielstart wacht die Hexe am Bett auf (im Unterschlupf).

# Hier steht das Bett, an dem die Hexe beim Spielstart aufwacht.
const START_LEVEL := "res://scenes/world/shelter.tscn"
# Niederlage: von so vielen zufälligen Stapeln geht je die Hälfte verloren.
const LOST_STACKS := 3

var level: Level
var _travelling := false

@onready var player: Player = $Player


func _ready() -> void:
	add_to_group("main")
	(player.get_node("Vitals") as Vitals).died.connect(_on_witch_defeated)
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


## Niederlage (Leben auf null): Die Nacht endet, die Hexe wacht im Bett auf,
## und ein paar Dinge aus der Tasche sind weg, Werkzeuge und Ausrüstung nie.
## Wie beim Schlafen wird danach gespeichert, damit man die Niederlage nicht
## durch Neuladen umgehen kann. Design: game_design.md, Abschnitt 7.
func _on_witch_defeated() -> void:
	if _travelling:
		return
	_travelling = true
	player.set_controls_enabled(false)
	(player.get_node("Combat") as Combat).set_active(false)
	await get_tree().create_timer(0.4).timeout
	await ScreenFade.fade_out()
	var lost := _lose_some_items()
	_load_level(START_LEVEL)
	var bed := get_tree().get_first_node_in_group("bed")
	if bed:
		player.global_position = bed.wake_spot.global_position
	player.facing = Vector2.DOWN
	player.camera.reset_smoothing()
	DayCycle.sleep_until_night()
	SaveGame.save_game()
	await get_tree().create_timer(1.0).timeout
	await ScreenFade.fade_in()
	player.set_controls_enabled(true)
	_travelling = false
	if lost.is_empty():
		Messages.post(tr("MSG_DEFEAT"))
	else:
		Messages.post(tr("MSG_DEFEAT_LOST") % ", ".join(lost))


## Nimmt von bis zu LOST_STACKS zufälligen Stapeln je die Hälfte (aufgerundet).
## Gibt zurück, was verloren ging, z. B. ["2× Mandrake"].
func _lose_some_items() -> Array[String]:
	var candidates: Array[int] = []
	for slot in Inventory.SIZE:
		var item := ItemData.from_id(Inventory.item_in_slot(slot))
		if item and item.type != ItemData.Type.TOOL:
			candidates.append(slot)
	candidates.shuffle()
	var lost: Array[String] = []
	for slot in candidates.slice(0, LOST_STACKS):
		var item_id := Inventory.item_in_slot(slot)
		var amount := ceili(Inventory.count_in_slot(slot) / 2.0)
		Inventory.remove_from_slot(slot, amount)
		lost.append("%d× %s" % [amount, Inventory.display_name_for(item_id)])
	return lost
