class_name RewardData
extends Resource

## Was eine Grimoire-Seite (oder später eine volle Herbarium-Seite, eine
## Disziplin-Stufe) bringt. Wird in andere Datendateien eingebettet.

enum Type {
	RECIPE,          # target_id = Ergebnis-Item des Rezepts
	ITEM,            # target_id = Item, value = Anzahl
	DIGITALIS_FORM,  # target_id = Form (staff, sickle …)
	LOCATION,        # target_id = Ort oder Versteck, als Hinweis
	XP,              # target_id = Disziplin, value = Erfahrungspunkte
	STAT,            # target_id = Wert (z. B. "brew_count"), value = Bonus
	DREAM,           # target_id = Traum in der nächsten Nacht
}

@export var type: Type = Type.RECIPE
@export var target_id: String = ""
@export var value: int = 1
