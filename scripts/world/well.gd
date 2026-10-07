extends StaticBody2D

## Ein alter Brunnen im Garten. Was die Hexe nicht mehr braucht, wirft sie
## hinein: E wirft ein Stück des Items in der Hand, Shift + E den ganzen
## Stapel. Das Wasser glimmt leicht magenta, der Brunnen ist nicht ganz
## gewöhnlich (vielleicht gibt er eines Tages etwas zurück).

const SPLASH_COLOR := Color("#788CB9")


func _on_interactable_interacted(_player: Node2D) -> void:
	var slot := Inventory.selected_slot
	var item_id := Inventory.item_in_slot(slot)
	if item_id == "":
		Messages.post("Tief unten glitzert etwas.")
		return
	var whole_stack := Input.is_action_pressed("float")
	var amount := Inventory.count_in_slot(slot) if whole_stack else 1
	var item_name := Inventory.display_name_for(item_id)
	Inventory.remove_from_slot(slot, amount)
	if amount > 1:
		Messages.post("Der ganze Stapel %s versinkt im Brunnen." % item_name)
	else:
		Messages.post("%s versinkt im Brunnen." % item_name)
	_splash()


func _splash() -> void:
	var drops := CPUParticles2D.new()
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = 10
	drops.lifetime = 0.5
	drops.direction = Vector2.UP
	drops.spread = 50.0
	drops.gravity = Vector2(0, 120)
	drops.initial_velocity_min = 20.0
	drops.initial_velocity_max = 45.0
	drops.color = SPLASH_COLOR
	drops.position = Vector2(0, -19)
	add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
