extends Node

## Gesuche am Anschlagbrett (Autoload): welche Zettel gerade hängen, was schon
## erledigt ist. Jede Nacht kommt ein neuer Zettel dazu, solange weniger als
## MAX_ACTIVE hängen; nach STAY_NIGHTS Nächten wird ein Zettel abgenommen.
## Das gibt jeder Nacht ein kleines Ziel, ohne Pflicht.
##
## Die Gesuche selbst sind Daten (data/requests/*.tres, RequestData).

signal changed

const FOLDER := "res://data/requests/"
const MAX_ACTIVE := 3
const STAY_NIGHTS := 3
# Beim neuen Spiel hängen gleich so viele, damit man in Nacht 1 etwas findet.
const START_NOTES := 2

# Hängende Zettel: [{"id": …, "posted": Nacht}], älteste zuerst.
var _active: Array[Dictionary] = []
# Erledigt: ID -> wie oft.
var _done: Dictionary = {}
var _all: Dictionary = {}


func _ready() -> void:
	for request: RequestData in DataFolder.load_all(FOLDER):
		_all[request.id] = request
	DayCycle.day_passed.connect(_on_day_passed)
	# Startet man direkt eine Szene (Editor), hängen trotzdem Zettel.
	# Neues Spiel und Laden setzen das gleich danach richtig.
	reset()


func reset() -> void:
	_active.clear()
	_done.clear()
	for i in START_NOTES:
		_post_one(DayCycle.day, i)
	changed.emit()


func get_request(id: String) -> RequestData:
	return _all.get(id)


## IDs der Zettel, die gerade hängen.
func active_ids() -> Array[String]:
	var ids: Array[String] = []
	for note in _active:
		ids.append(String(note["id"]))
	return ids


func done_count(id: String) -> int:
	return int(_done.get(id, 0))


## Hat die Hexe alles dabei?
func can_deliver(id: String) -> bool:
	var request := get_request(id)
	return request != null and id in active_ids() and Inventory.count(request.item_id) >= request.amount


func deliverable_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in active_ids():
		if can_deliver(id):
			ids.append(id)
	return ids


## Gibt ab: Items aus der Tasche, Belohnung rein, Zettel ab. false, wenn es
## nicht geht (fehlt etwas, oder die Tasche ist für die Belohnung zu voll).
func deliver(id: String) -> bool:
	if not can_deliver(id):
		return false
	var request := get_request(id)
	for reward in request.rewards:
		if reward.type == RewardData.Type.ITEM and not Inventory.has_room_for(reward.target_id, reward.value):
			Messages.deny(tr("MSG_BAG_FULL"))
			return false
	Inventory.remove(request.item_id, request.amount)
	for reward in request.rewards:
		_grant(reward)
	if request.hint_recipe != "":
		Grimoire.hint_ingredient(request.hint_recipe, request.hint_ingredient)
	WorldState.set_flag(request.sets_flag)
	_done[id] = done_count(id) + 1
	# filter() gibt ein untypisiertes Array zurück, assign() behält den Typ.
	_active.assign(_active.filter(func(note: Dictionary) -> bool: return note["id"] != id))
	# Für das Kapitel People und spätere Freundschaft: wem geholfen wurde.
	Grimoire.report("deliver", {"id": request.giver})
	Sfx.play("ui/item_get")
	changed.emit()
	return true


## Kurzer Text, was es als Lohn gibt (für den Zettel).
func reward_text(request: RequestData) -> String:
	var parts: PackedStringArray = []
	for reward in request.rewards:
		match reward.type:
			RewardData.Type.ITEM:
				parts.append("%d× %s" % [reward.value, Inventory.display_name_for(reward.target_id)])
			RewardData.Type.RECIPE:
				parts.append(tr("REQUEST_REWARD_RECIPE"))
			RewardData.Type.STAT:
				if reward.target_id == "chest_capacity":
					parts.append(tr("REQUEST_REWARD_CHEST"))
			RewardData.Type.XP:
				parts.append(tr("REQUEST_REWARD_XP"))
	if request.hint_recipe != "":
		parts.append(tr("REQUEST_REWARD_HINT"))
	return ", ".join(parts)


func _grant(reward: RewardData) -> void:
	if reward.type == RewardData.Type.STAT and reward.target_id == "chest_capacity":
		Inventory.chest_capacity = mini(Inventory.chest_capacity + reward.value, Inventory.CHEST_MAX)
		Messages.post(tr("MSG_CHEST_BIGGER"))
	else:
		Grimoire.grant(reward)


func _on_day_passed(day: int) -> void:
	_active.assign(_active.filter(func(note: Dictionary) -> bool: return day - int(note["posted"]) < STAY_NIGHTS))
	if _active.size() < MAX_ACTIVE:
		_post_one(day, 0)
	changed.emit()


## Hängt einen passenden Zettel auf. Gezogen wird nach Gewicht, aber fest pro
## Nacht (gleiche Nacht = gleicher Zettel, auch nach dem Neuladen).
func _post_one(day: int, salt: int) -> void:
	var busy_givers: Array[String] = []
	for id in active_ids():
		busy_givers.append(get_request(id).giver)
	var candidates: Array[RequestData] = []
	var total := 0
	var ids := _all.keys()
	ids.sort()
	for id in ids:
		var request: RequestData = _all[id]
		if id in active_ids() or request.giver in busy_givers:
			continue
		if request.can_post(day, Moon.phase(), done_count(id)):
			candidates.append(request)
			total += maxi(request.weight, 1)
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(day, salt))
	var roll := rng.randi_range(1, total)
	for request in candidates:
		roll -= maxi(request.weight, 1)
		if roll <= 0:
			_active.append({"id": request.id, "posted": day})
			return


func get_save_data() -> Dictionary:
	return {"active": _active.duplicate(true), "done": _done.duplicate()}


## Unbekannte IDs (umbenannte oder gelöschte Gesuche) werden aussortiert.
func load_save_data(data: Dictionary) -> void:
	_active.clear()
	_done.clear()
	var active: Variant = data.get("active", [])
	if active is Array:
		for note: Variant in active:
			if note is Dictionary and _all.has(String(note.get("id", ""))):
				_active.append({"id": String(note["id"]), "posted": int(note.get("posted", DayCycle.day))})
	var done: Variant = data.get("done", {})
	if done is Dictionary:
		for id: Variant in done:
			if _all.has(String(id)):
				_done[String(id)] = int(done[id])
	# Älterer Spielstand ohne Gesuche: wie ein neues Spiel, damit Zettel hängen.
	if not data.has("active"):
		for i in START_NOTES:
			_post_one(DayCycle.day, i)
	changed.emit()
