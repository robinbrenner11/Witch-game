extends Control

## Pausemenü (Esc): Fortsetzen, Einstellungen, Speichern und beenden. Öffnet
## nur, wenn kein anderes Fenster offen ist und die Hexe gerade frei ist
## (nicht beim Schlafen oder Ortswechsel).
##
## Steht in der UI vor den anderen Fenstern, damit diese Esc zuerst bekommen
## und sich selbst schließen können.

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var menu: Control = $Scaled/Menu
@onready var resume_button: Button = %ResumeButton
@onready var settings_menu: Control = $SettingsMenu


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_set_open(false)
	elif not get_tree().paused and _player_is_free():
		_set_open(true)
	else:
		return
	get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	Sfx.play("ui/open" if open else "ui/close")
	visible = open
	get_tree().paused = open
	if open:
		menu.show()
		resume_button.grab_focus()


func _player_is_free() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_physics_processing()


func _on_resume_button_pressed() -> void:
	_set_open(false)


func _on_settings_button_pressed() -> void:
	menu.hide()
	settings_menu.open()
	await settings_menu.closed
	menu.show()
	resume_button.grab_focus()


func _on_save_quit_button_pressed() -> void:
	SaveGame.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
