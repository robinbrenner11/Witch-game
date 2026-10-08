class_name SpreadDiscipline
extends GrimoireSpread

## Disziplin (Herbalism, Brewing …).
## Links: Stufe, Erfahrungsbalken, wodurch die Disziplin wächst, und jede
## Stufe mit dem, was sie bringt. Geschenke (Items) holt man hier ab; Werte
## und Rezepte gelten sofort. Am Rand wächst die Erfahrungsranke: ein Blatt
## pro Stufe, Knospen an den Meilensteinen, die nach der Pfadwahl aufblühen.
## Rechts: die Hexenpfade als Karten. Wählen braucht einen zweiten Klick.
## Design: docs/design/grimoire.md, Abschnitte 3 und 4.

const ROW_HEIGHT := 16.0
const VINE_WIDTH := 10.0
const NUMBER_WIDTH := 16.0

var discipline: DisciplineData
# Pfad, bei dem "Wählen" einmal geklickt wurde und auf Bestätigung wartet.
var _confirming := ""


func _init(owner_book: GrimoireBook, for_chapter: ChapterData) -> void:
	super(owner_book, for_chapter)
	discipline = DisciplineData.from_id(chapter.id)


static func seen_key(discipline_id: String, level: int) -> String:
	return "level/%s/%d" % [discipline_id, level]


func has_new() -> bool:
	if Grimoire.claimable_count(discipline.id) > 0:
		return true
	for milestone in discipline.milestone_levels:
		if Grimoire.is_choice_pending(discipline.id, milestone):
			return true
	var level := Grimoire.level(discipline.id)
	return level > 0 and not Grimoire.is_seen(seen_key(discipline.id, level))


func on_close() -> void:
	_confirming = ""


func build(left: Control, right: Control) -> void:
	var level := Grimoire.level(discipline.id)
	_build_levels(left, level)
	_build_paths(right, level)
	if level > 0:
		Grimoire.mark_seen(seen_key(discipline.id, level))


# --- Linke Seite -------------------------------------------------------------------

func _build_levels(page: Control, level: int) -> void:
	var header := HBoxContainer.new()
	header.add_child(BookStyle.label(chapter.title_key, BookStyle.INK_VESPERA_TITLE))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var level_key := "BOOK_LEVEL_MAX" if level >= discipline.max_level else "BOOK_LEVEL"
	header.add_child(BookStyle.label(tr(level_key) % level, BookStyle.INK))
	page.add_child(header)
	page.add_child(BookStyle.rule(text_width))

	# Erfahrung bis zur nächsten Stufe als Balken mit Zahlen daneben.
	var xp := Grimoire.xp(discipline.id)
	if level < discipline.max_level:
		var from := discipline.xp_for_level(level)
		var to := discipline.xp_for_level(level + 1)
		var bar_row := HBoxContainer.new()
		var bar := BookStyle.progress_bar(float(xp - from) / maxf(to - from, 1), 120)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar_row.add_child(bar)
		bar_row.add_child(BookStyle.label("%d / %d" % [xp, to], BookStyle.INK_FAINT))
		page.add_child(bar_row)
	page.add_child(BookStyle.label(tr("BOOK_GROWS_BY") % _sources_text(), BookStyle.INK_FAINT, text_width))

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	for row_level in range(1, discipline.max_level + 1):
		rows.add_child(_level_row(row_level, level, xp))
	page.add_child(rows)


## "Pflanzen · Ernten", aus den Aktionen, die Erfahrung bringen.
func _sources_text() -> String:
	var names: Array[String] = []
	for action: String in discipline.xp_small:
		names.append(tr("ACTION_" + action.to_upper()))
	for action: String in discipline.xp_first:
		var name := tr("ACTION_" + action.to_upper())
		if not names.has(name):
			names.append(name)
	return " · ".join(names)


## Eine Zeile: Rankenstück, Stufennummer, was die Stufe bringt, Abholen.
func _level_row(row_level: int, level: int, xp: int) -> Control:
	var reached := row_level <= level
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.custom_minimum_size.x = text_width
	var vine := VinePiece.new()
	vine.reached = reached
	vine.milestone = row_level in discipline.milestone_levels
	vine.bloomed = vine.milestone and Grimoire.chosen_path(discipline.id, row_level) != ""
	# Der Stängel wächst schon ein Stück in die nächste Stufe hinein.
	if row_level == level + 1:
		var from := discipline.xp_for_level(level)
		var to := discipline.xp_for_level(row_level)
		vine.growth = clampf(float(xp - from) / maxf(to - from, 1), 0.0, 1.0)
	elif reached:
		vine.growth = 1.0
	row.add_child(vine)

	var number := BookStyle.label(str(row_level), BookStyle.GOLD_DARK if reached else BookStyle.INK_FAINT)
	number.custom_minimum_size.x = NUMBER_WIDTH
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)

	var reward := discipline.reward_for_level(row_level)
	var text := reward_text(reward)
	var color := BookStyle.INK if reached else BookStyle.INK_FAINT
	if vine.milestone:
		text = tr("BOOK_MILESTONE")
		color = BookStyle.GOLD_DARK if reached else BookStyle.INK_FAINT
	var label := BookStyle.label(text, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	# Rechts: abholen, abgeholt (Häkchen) oder nichts.
	if Grimoire.is_reward_claimable(discipline.id, row_level):
		var take := BookStyle.button("BOOK_CLAIM")
		take.pressed.connect(func() -> void: Grimoire.claim_reward(discipline.id, row_level))
		row.add_child(take)
	elif reward and reward.type == RewardData.Type.ITEM and Grimoire.is_reward_claimed(discipline.id, row_level):
		row.add_child(Check.new())
	return row


## Was eine Belohnung bringt, kurz in einer Zeile.
static func reward_text(reward: RewardData) -> String:
	if reward == null:
		return ""
	match reward.type:
		RewardData.Type.ITEM:
			return TranslationServer.translate("REWARD_ITEM") % [reward.value, Inventory.display_name_for(reward.target_id)]
		RewardData.Type.RECIPE:
			return TranslationServer.translate("REWARD_RECIPE") % Inventory.display_name_for(reward.target_id)
		RewardData.Type.STAT:
			return TranslationServer.translate("STAT_" + reward.target_id.to_upper()) % reward.value
		RewardData.Type.XP:
			return TranslationServer.translate("REWARD_XP") % [reward.value,
					TranslationServer.translate("CHAPTER_" + reward.target_id.to_upper())]
	return ""


# --- Rechte Seite ------------------------------------------------------------------

func _build_paths(page: Control, level: int) -> void:
	page.add_child(BookStyle.heading("BOOK_PATHS", BookStyle.INK_VESPERA_TITLE, text_width))
	for milestone in discipline.milestone_levels:
		page.add_child(BookStyle.label(tr("BOOK_LEVEL") % milestone, BookStyle.GOLD_DARK))
		var before := Grimoire.chosen_path(discipline.id, 5) if milestone > 5 else ""
		if milestone > 5 and before == "":
			page.add_child(BookStyle.label("BOOK_PATH_UNKNOWN", BookStyle.INK_FAINT, text_width))
			continue
		var chosen := Grimoire.chosen_path(discipline.id, milestone)
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 4)
		for path in PathData.options(discipline.id, milestone, before):
			cards.add_child(_path_card(path, chosen, level))
		page.add_child(cards)
	if book.opened_at_lectern:
		_add_respec(page)


## Eine Karte pro Pfad: Name, Wirkung, und je nach Zustand Wählen,
## "Dein Pfad" oder ab welcher Stufe.
func _path_card(path: PathData, chosen: String, level: int) -> Control:
	var is_chosen := chosen == path.id
	var card := PathCard.new()
	if is_chosen:
		card.state = PathCard.State.CHOSEN
	elif Grimoire.can_choose(path):
		card.state = PathCard.State.OPEN
	var width := (text_width - 4) / 2.0
	card.custom_minimum_size.x = width
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.position = Vector2(4, 2)
	var inner := width - 8
	var faint := chosen != "" and not is_chosen
	var title_color := BookStyle.INK_PLAYER if is_chosen else (BookStyle.INK_FAINT if faint else BookStyle.INK)
	box.add_child(BookStyle.label(path.title_key, title_color, inner))
	box.add_child(BookStyle.label(path.description_key, BookStyle.INK_FAINT if faint else BookStyle.INK, inner))
	if is_chosen:
		box.add_child(BookStyle.label("BOOK_PATH_CHOSEN", BookStyle.INK_PLAYER))
	elif Grimoire.can_choose(path):
		var key := "BOOK_PATH_CONFIRM" if _confirming == path.id else "BOOK_PATH_CHOOSE"
		var choose := BookStyle.button(key)
		choose.pressed.connect(func() -> void:
			if _confirming == path.id:
				_confirming = ""
				Grimoire.choose_path(path)
			else:
				_confirming = path.id
				book.refresh())
		box.add_child(choose)
	elif level < path.level:
		box.add_child(BookStyle.label(tr("BOOK_PATH_LOCKED") % path.level, BookStyle.INK_FAINT, inner))
	card.content = box
	card.add_child(box)
	return card


## Am Lesepult: gewählte Pfade gegen seltene Items zurücksetzen.
func _add_respec(page: Control) -> void:
	for milestone in discipline.milestone_levels:
		var path := PathData.from_id(Grimoire.chosen_path(discipline.id, milestone))
		if path == null:
			continue
		var cost: Array[String] = []
		for item_id: String in path.respec_cost:
			cost.append("%d× %s" % [path.respec_cost[item_id], Inventory.display_name_for(item_id)])
		var change := BookStyle.button(tr("BOOK_PATH_CHANGE") % ", ".join(cost))
		change.disabled = not Grimoire.can_respec(discipline.id, milestone)
		change.pressed.connect(func() -> void: Grimoire.respec(discipline.id, milestone))
		page.add_child(change)


## Rahmen um eine Pfadkarte: gewählt magenta mit Fingerhut, wählbar gold,
## sonst gepunktet. Die Karte wächst mit ihrem Inhalt.
class PathCard:
	extends Control

	enum State { OPEN, CHOSEN, CLOSED }
	var state := State.CLOSED
	var content: Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.resized.connect(_fit)
		_fit.call_deferred()

	func _fit() -> void:
		custom_minimum_size.y = content.size.y + 5
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		match state:
			State.CHOSEN:
				draw_rect(rect, Color(BookStyle.MAGENTA, 0.08))
				BookStyle.draw_frame(self, rect, BookStyle.MAGENTA)
				BookStyle.draw_foxglove(self, Vector2(size.x - 9, 2))
			State.OPEN:
				BookStyle.draw_frame(self, rect, BookStyle.GOLD)
			State.CLOSED:
				BookStyle.draw_dotted_rect(self, rect, BookStyle.INK_FAINT)


## Häkchen für abgeholte Geschenke.
class Check:
	extends Control

	func _ready() -> void:
		custom_minimum_size = Vector2(9, SpreadDiscipline.ROW_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		BookStyle.draw_check(self, Vector2(1, 6), BookStyle.GOLD_DARK)


## Ein Stück der Erfahrungsranke neben einer Stufenzeile.
class VinePiece:
	extends Control

	var reached := false
	var growth := 0.0
	var milestone := false
	var bloomed := false

	func _ready() -> void:
		custom_minimum_size = Vector2(SpreadDiscipline.VINE_WIDTH, SpreadDiscipline.ROW_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := 4.0
		# Noch nicht gewachsen: nur eine gepunktete Spur.
		for y in range(0, int(size.y), 3):
			draw_rect(Rect2(x, y, 1, 1), BookStyle.SHEET_SHADOW)
		var grown := roundf(size.y * growth)
		if grown > 0:
			draw_rect(Rect2(x, 0, 2, grown), BookStyle.LEAF_DARK)
		if reached:
			# Ein Blatt pro Stufe, nach rechts geneigt.
			draw_rect(Rect2(x + 2, 6, 3, 2), Color("#30624A"))
			draw_rect(Rect2(x + 4, 5, 2, 1), Color("#30624A"))
		if milestone:
			if bloomed:
				# Aufgeblüht: Magenta-Blüte mit goldener Mitte.
				for offset: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
					draw_rect(Rect2(Vector2(x, 8) + offset * 2, Vector2(2, 2)), BookStyle.MAGENTA)
				draw_rect(Rect2(x, 8, 2, 2), BookStyle.GOLD)
			else:
				draw_rect(Rect2(x - 1, 7, 3, 3), BookStyle.MAGENTA if reached else BookStyle.SHEET_SHADOW_DEEP)
