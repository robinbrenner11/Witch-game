extends CanvasLayer

## Schwarzblende über dem ganzen Bild. Läuft als Autoload, weil sie Szenen
## überdauern muss: Später blendet sie auch beim Wechsel zwischen
## Unterschlupf, Garten und Wald ab und wieder auf.
##
## Benutzung mit await, damit der Aufrufer wartet, bis das Bild schwarz ist:
##     await ScreenFade.fade_out()

const DURATION := 0.6

var _rect: ColorRect


func _ready() -> void:
	# Über allem anderen, auch über der UI.
	layer = 100
	_rect = ColorRect.new()
	# Tiefschwarz aus der Palette statt reinem Schwarz.
	_rect.color = Color("#0E0A14")
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Unsichtbar soll sie keine Mausklicks schlucken.
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	# Ein Tween verändert einen Wert über die Zeit, hier die Deckkraft.
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", alpha, DURATION)
	await tween.finished
