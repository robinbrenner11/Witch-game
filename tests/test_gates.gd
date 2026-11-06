## Sperren (Gates): Man sieht sie, bevor man sie öffnen kann, und beim
## Öffnen blendet das Aussehen sichtbar über (zu → offen).
extends TestCase


func before_each() -> void:
	SaveGame.new_game()


func _gate_with_looks() -> Gate:
	var gate := Gate.new()
	gate.required_flag = "test_gate_open"
	var closed := Sprite2D.new()
	closed.name = "Closed"
	var open := Sprite2D.new()
	open.name = "Open"
	gate.add_child(closed)
	gate.add_child(open)
	tree.root.add_child(gate)
	return gate


func test_fade_from_closed_to_open() -> void:
	var gate := _gate_with_looks()
	await tree.process_frame
	var closed := gate.get_node("Closed") as CanvasItem
	var open := gate.get_node("Open") as CanvasItem
	check(closed.visible and not open.visible, "Zu: nur das geschlossene Bild")
	WorldState.set_flag("test_gate_open")
	await tree.process_frame
	check(open.visible and closed.visible, "Beim Öffnen sind kurz beide zu sehen (Überblenden)")
	check(open.modulate.a < 1.0, "Offenes Bild blendet erst ein")
	await tree.create_timer(Gate.FADE_TIME + 0.2).timeout
	check(open.visible and not closed.visible, "Danach nur noch offen")
	check_eq(open.modulate.a, 1.0, "Offen voll sichtbar")
	check_eq(closed.modulate.a, 1.0, "Geschlossenes Bild für später zurückgesetzt")
	gate.queue_free()
	await tree.process_frame


func test_already_open_shows_instantly() -> void:
	WorldState.set_flag("test_gate_open")
	var gate := _gate_with_looks()
	await tree.process_frame
	check(not (gate.get_node("Closed") as CanvasItem).visible, "Schon offen: kein Überblenden beim Betreten")
	check_eq((gate.get_node("Open") as CanvasItem).modulate.a, 1.0, "Sofort voll sichtbar")
	gate.queue_free()
	await tree.process_frame


## Die Sperren im Seewald haben echte Bilder für beide Zustände (keine
## Farbflächen mehr), der Mondsteg ist auch geschlossen schwach zu sehen.
func test_lakewood_gates_have_looks() -> void:
	var lakewood := (load("res://scenes/world/lakewood.tscn") as PackedScene).instantiate()
	for gate_name in ["SwampVines", "MoonBridge"]:
		var gate := lakewood.get_node(gate_name)
		for state in ["Closed", "Open"]:
			var look := gate.get_node_or_null(state)
			check(look != null, "%s hat %s" % [gate_name, state])
			if look:
				check(not look.find_children("*", "Sprite2D").is_empty(), "%s/%s zeigt ein Bild" % [gate_name, state])
				check(look.find_children("*", "ColorRect").is_empty(), "%s/%s ohne Farbflächen" % [gate_name, state])
	check(lakewood.get_node("MoonBridge/Closed/Glimmer") is Shimmer, "Geschlossener Mondsteg schimmert")
	lakewood.free()
