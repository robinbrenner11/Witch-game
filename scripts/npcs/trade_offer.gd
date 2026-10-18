class_name TradeOffer
extends Resource

## Ein Tauschangebot eines NPCs: so viel von einem Item gegen so viel von
## einem anderen. Kein Geld (docs/design/game_design.md, Tausch). Jedes
## Angebot ist eine Datei in data/trades/<npc>/, neues Angebot = neue Datei.
##
## Statt eines Items kann es eine Belohnung geben (reward, z. B. ein Upgrade
## bei Gnarl) oder gar nichts: Dann ist es eine Gabe, die nur ein Flag setzt
## (Gnarl einen Heiltrank bringen).

const FOLDER := "res://data/trades/"

@export var id: String = ""
@export var wants_item: String = ""
@export var wants_amount: int = 1
## Zweites Material, z. B. für Upgrades. Leer = nur eins.
@export var also_wants_item: String = ""
@export var also_wants_amount: int = 1
## Leer = kein Item (dann reward oder nur sets_flag).
@export var gives_item: String = ""
@export var gives_amount: int = 1
## Belohnung statt Item, z. B. UPGRADE staff 2. Ein Upgrade wird nur
## angeboten, solange die Hexe genau die Stufe davor hat.
@export var reward: RewardData
## Wie oft pro Nacht (0 = beliebig oft). Für seltene Dinge.
@export var per_night: int = 0
## Nur in diesen Mondphasen (Moon.Phase). Leer = immer.
@export var moon_phases: Array[int] = []
@export var requires_flags: Array[String] = []
## Nicht mehr, sobald eines dieser Flags gesetzt ist.
@export var blocked_by_flags: Array[String] = []
## Wird nach dem Tausch gesetzt (WorldState).
@export var sets_flag: String = ""
## Wird erst ab der nächsten Nacht gesetzt, z. B. Gnarl zieht über Tag um.
@export var sets_flag_next_night: String = ""
## Meldung nach dem Tausch (Text-Schlüssel). Leer = keine.
@export var after_message: String = ""


static func all_for(npc_id: String) -> Array[TradeOffer]:
	var result: Array[TradeOffer] = []
	var folder := FOLDER + npc_id + "/"
	if not DirAccess.dir_exists_absolute(folder):
		return result
	for resource in DataFolder.load_all(folder):
		result.append(resource as TradeOffer)
	result.sort_custom(func(a: TradeOffer, b: TradeOffer) -> bool: return a.id < b.id)
	return result


## Wird das Angebot gerade gemacht (Mond, Flags, heute schon oft genug)?
func is_offered(npc_id: String) -> bool:
	if not moon_phases.is_empty() and Moon.phase() not in moon_phases:
		return false
	if reward and reward.type == RewardData.Type.UPGRADE and not _upgrade_is_next():
		return false
	if reward and reward.type == RewardData.Type.PAGE and Grimoire.is_page_found(reward.target_id):
		return false
	return WorldState.has_all(requires_flags) and WorldState.has_none(blocked_by_flags) 		and (per_night <= 0 or times_tonight(npc_id) < per_night)


## Hat die Hexe die Form (bzw. das Werkzeug) und genau die Stufe davor?
func _upgrade_is_next() -> bool:
	var target := reward.target_id
	var owned := Grimoire.known_forms().has(target) or Grimoire.UPGRADE_TOOLS.has(target)
	return owned and Grimoire.upgrade_level(target) == reward.value - 1


func times_tonight(npc_id: String) -> int:
	var count := 0
	while WorldState.did_tonight(_night_key(npc_id, count)):
		count += 1
	return count


func can_afford() -> bool:
	return Inventory.count(wants_item) >= wants_amount 		and (also_wants_item == "" or Inventory.count(also_wants_item) >= also_wants_amount)


## Tauscht. false (mit Meldung), wenn etwas fehlt oder kein Platz ist.
func trade(npc_id: String) -> bool:
	if not can_afford():
		var missing := wants_item if Inventory.count(wants_item) < wants_amount else also_wants_item
		Messages.deny(tr("MSG_TRADE_MISSING") % Inventory.display_name_for(missing))
		return false
	if gives_item != "" and not Inventory.has_room_for(gives_item, gives_amount):
		Messages.deny(tr("MSG_BAG_FULL"))
		return false
	Inventory.remove(wants_item, wants_amount)
	if also_wants_item != "":
		Inventory.remove(also_wants_item, also_wants_amount)
	if gives_item != "":
		Inventory.add(gives_item, gives_amount)
	if reward:
		Grimoire.grant(reward)
	WorldState.set_flag(sets_flag)
	WorldState.set_flag_next_night(sets_flag_next_night)
	if after_message != "":
		Messages.post(tr(after_message))
	WorldState.mark_tonight(_night_key(npc_id, times_tonight(npc_id)))
	Grimoire.report("trade", {"id": npc_id})
	Sfx.play("ui/item_get")
	return true


## Text für die Antwort-Auswahl, z. B. "4× Wildkraut gegen 2× Alraunensamen",
## "Stab II: 2× Höhlenkristall, 3× Bitterblütenblatt" oder "1× Heiltrank geben".
func label() -> String:
	var cost := cost_text()
	if reward and reward.type == RewardData.Type.UPGRADE:
		return tr("TRADE_UPGRADE") % [tr(Grimoire.upgrade_key(reward.target_id, reward.value)), cost]
	if reward and reward.type == RewardData.Type.PAGE:
		return tr("TRADE_PAGE") % cost
	if gives_item == "":
		return tr("TRADE_GIVE") % cost
	return tr("TRADE_OFFER") % [cost, gives_amount, Inventory.display_name_for(gives_item)]


## Was das Angebot kostet, z. B. "2× Höhlenkristall, 3× Bitterblütenblatt".
func cost_text() -> String:
	var cost := "%d× %s" % [wants_amount, Inventory.display_name_for(wants_item)]
	if also_wants_item != "":
		cost += ", %d× %s" % [also_wants_amount, Inventory.display_name_for(also_wants_item)]
	return cost


## Das Upgrade-Angebot für diese Stufe, bei welchem NPC auch immer (oder null).
static func for_upgrade(target_id: String, at_level: int) -> TradeOffer:
	for npc in DataFolder.load_all(NpcData.FOLDER):
		for offer in all_for((npc as NpcData).id):
			if offer.reward and offer.reward.type == RewardData.Type.UPGRADE 					and offer.reward.target_id == target_id and offer.reward.value == at_level:
				return offer
	return null


func _night_key(npc_id: String, index: int) -> String:
	return "trade/%s/%s/%d" % [npc_id, id, index]
