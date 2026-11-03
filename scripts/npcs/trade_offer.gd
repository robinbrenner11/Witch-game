class_name TradeOffer
extends Resource

## Ein Tauschangebot eines NPCs: so viel von einem Item gegen so viel von
## einem anderen. Kein Geld (docs/design/game_design.md, Tausch). Jedes
## Angebot ist eine Datei in data/trades/<npc>/, neues Angebot = neue Datei.

const FOLDER := "res://data/trades/"

@export var id: String = ""
@export var wants_item: String = ""
@export var wants_amount: int = 1
## Leer = eine Gabe ohne Gegenleistung, z. B. ein Heiltrank für jemanden,
## dem es schlecht geht. Dann zählt meist das Flag (sets_flag).
@export var gives_item: String = ""
@export var gives_amount: int = 1
## Wie oft pro Nacht (0 = beliebig oft). Für seltene Dinge.
@export var per_night: int = 0
## Nur in diesen Mondphasen (Moon.Phase). Leer = immer.
@export var moon_phases: Array[int] = []
@export var requires_flags: Array[String] = []
## Nicht mehr angeboten, sobald eines dieser Flags gesetzt ist.
@export var blocked_by_flags: Array[String] = []
## Wird nach dem Tausch gesetzt (sofort bzw. erst mit der nächsten Nacht).
## Ein Gespräch, das dieses Flag braucht, folgt direkt auf den Tausch
## (siehe Npc._offer_trades).
@export var sets_flag: String = ""
@export var sets_flag_next_night: String = ""


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
	if not WorldState.has_none(blocked_by_flags):
		return false
	return WorldState.has_all(requires_flags) and (per_night <= 0 or times_tonight(npc_id) < per_night)


func times_tonight(npc_id: String) -> int:
	var count := 0
	while WorldState.did_tonight(_night_key(npc_id, count)):
		count += 1
	return count


func can_afford() -> bool:
	return Inventory.count(wants_item) >= wants_amount


## Tauscht. false (mit Meldung), wenn etwas fehlt oder kein Platz ist.
func trade(npc_id: String) -> bool:
	if not can_afford():
		Messages.deny(tr("MSG_TRADE_MISSING") % Inventory.display_name_for(wants_item))
		return false
	if gives_item != "" and not Inventory.has_room_for(gives_item, gives_amount):
		Messages.deny(tr("MSG_BAG_FULL"))
		return false
	Inventory.remove(wants_item, wants_amount)
	WorldState.mark_tonight(_night_key(npc_id, times_tonight(npc_id)))
	Grimoire.report("trade", {"id": npc_id})
	if gives_item != "":
		Inventory.add(gives_item, gives_amount)
		# Was man nur ertauschen kann (z. B. Blütenknospe), entdeckt so seinen
		# Herbarium-Eintrag.
		Grimoire.report("obtain", {"id": gives_item})
	WorldState.set_flag(sets_flag)
	WorldState.set_flag_next_night(sets_flag_next_night)
	Sfx.play("ui/item_get")
	return true


## Text für die Antwort-Auswahl, z. B. "4× Wildkraut gegen 2× Alraunensamen".
func label() -> String:
	if gives_item == "":
		return tr("TRADE_GIVE") % [wants_amount, Inventory.display_name_for(wants_item)]
	return tr("TRADE_OFFER") % [wants_amount, Inventory.display_name_for(wants_item),
			gives_amount, Inventory.display_name_for(gives_item)]


func _night_key(npc_id: String, index: int) -> String:
	return "trade/%s/%s/%d" % [npc_id, id, index]
