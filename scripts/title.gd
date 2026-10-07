extends Control

## Titelbildschirm von Bitterbloom: Fortsetzen, Neues Spiel, Einstellungen,
## Beenden. Hier wird entschieden, ob ein Spielstand geladen oder ein neues
## Spiel begonnen wird – erst danach startet main.tscn.

const GAME_SCENE := "res://scenes/main.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"

# Neues Spiel bei vorhandenem Spielstand braucht einen zweiten Klick.
var _confirm_new_game := false

@onready var menu: Control = $Scaled/Menu
@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var settings_menu: Control = $SettingsMenu


func _ready() -> void:
	# Falls man aus dem Pausemenü kommt, steht die Pause evtl. noch.
	get_tree().paused = false
	continue_button.disabled = not SaveGame.has_save()
	_focus_first_button()


func _on_continue_button_pressed() -> void:
	if SaveGame.load_game():
		_start()


func _on_new_game_button_pressed() -> void:
	if SaveGame.has_save() and not _confirm_new_game:
		_confirm_new_game = true
		new_game_button.text = "Wirklich neu beginnen?"
		return
	SaveGame.new_game()
	# Ein neues Spiel beginnt mit der kurzen Einleitung.
	get_tree().change_scene_to_file(INTRO_SCENE)


func _on_settings_button_pressed() -> void:
	menu.hide()
	settings_menu.open()
	await settings_menu.closed
	menu.show()
	_focus_first_button()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


## Fokus für Tastatur-Steuerung (Pfeiltasten + Enter).
func _focus_first_button() -> void:
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()
