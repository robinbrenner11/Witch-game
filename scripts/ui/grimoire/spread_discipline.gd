class_name SpreadDiscipline
extends GrimoireSpread

## Disziplin (Herbalism, Brewing …): links Stufe, Erfahrung und was jede Stufe
## bringt, mit der Erfahrungsranke am Rand (ein Blatt pro Stufe, Knospen an
## den Meilensteinen, die nach der Pfadwahl aufblühen). Rechts die
## Hexenpfade. Design: docs/design/grimoire.md, Abschnitte 3 und 4.

const ROW_HEIGHT := 13.0
const VINE_WIDTH := 12.0

var discipline: DisciplineData


func _init(owner_book: GrimoireBook, for_chapter: ChapterData) -> void:
	super(owner_book, for_chapter)
	discipline = DisciplineData.from_id(chapter.id)


static func seen_key(discipline_id: String, level: int) -> String:
	return "level/%s/%d" % [discipline_id, level]


func has_new() -> bool:
	for milestone in discipline.milestone_levels:
		if Grimoire.is_choice_pending(discipline.id, milestone):
			return true
	var level := Grimoire.level(discipline.id)
	return level > 0 and not Grimoire.is_seen(seen_key(discipline.id, level))


func build(left: Control, right: Control) -> void:
	var level := Grimoire.level(discipline.id)
	_build_levels(left, level)
	_build_paths(right, level)
	if level > 0:
		Grimoire.mark_seen(seen_key(discipline.id, level))


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

	# Erfahrung bis zur nächsten Stufe, z. B. 45 / 80.
	var xp := Grimoire.xp(discipline.id)
	if level < discipline.max_level:
		page.add_child(BookStyle.label("%d / %d" % [xp, discipline.xp_for_level(level + 1)], BookStyle.INK_FAINT))

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	for row_level in range(1, discipline.max_level + 1):
		rows.add_child(_level_row(row_level, level, xp))
	page.add_child(rows)


## Eine Zeile: Rankenstück, Stufennummer, was die Stufe bringt.
func _level_row(row_level: int, level: int, xp: int) -> Control:
	var reached := row_level <= level
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
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
	var color := BookStyle.INK if reached else BookStyle.INK_FAINT
	# Stufennummer in Gold, damit sie sich von Anzahlen ("2 Moon Chalice Seeds") abhebt.
	row.add_child(BookStyle.label("%2d" % row_level, BookStyle.GOLD_DARK if reached else BookStyle.INK_FAINT))
	var text := _reward_text(discipline.reward_for_level(row_level))
	if vine.milestone:
		text = tr("BOOK_MILESTONE")
		color = BookStyle.GOLD_DARK if reached else BookStyle.INK_FAINT
	row.add_child(BookStyle.label(text, color))
	return row


## Was eine Belohnung bringt, in einer Zeile.
static func _reward_text(reward: RewardData) -> String:
	if reward == null:
		return ""
	match reward.type:
		RewardData.Type.ITEM:
			return TranslationServer.translate("REWARD_ITEM") % [reward.value, Inventory.display_name_for(reward.target_id)]
		RewardData.Type.RECIPE:
			return TranslationServer.translate("REWARD_RECIPE") % Inventory.display_name_for(reward.target_id)
		RewardData.Type.STAT:
			return TranslationServer.translate("STAT_" + reward.target_id.to_upper()) % reward.value
	return ""


func _build_paths(page: Control, level: int) -> void:
	page.add_child(BookStyle.heading("BOOK_PATHS", BookStyle.INK_VESPERA_TITLE, text_width))
	for milestone in discipline.milestone_levels:
		page.add_child(BookStyle.label(tr("BOOK_LEVEL") % milestone, BookStyle.GOLD_DARK))
		var before := Grimoire.chosen_path(discipline.id, 5) if milestone > 5 else ""
		if milestone > 5 and before == "":
			page.add_child(BookStyle.label("BOOK_PATH_UNKNOWN", BookStyle.INK_FAINT, text_width))
			continue
		var chosen := Grimoire.chosen_path(discipline.id, milestone)
		for path in PathData.options(discipline.id, milestone, before):
			page.add_child(_path_box(path, chosen, level))


func _path_box(path: PathData, chosen: String, level: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var is_chosen := chosen == path.id
	# Gewählt: in der Tinte der Spielerin. Nicht gewählt oder noch zu: blass.
	var title_color := BookStyle.INK_PLAYER if is_chosen else (BookStyle.INK if chosen == "" else BookStyle.INK_FAINT)
	var title := HBoxContainer.new()
	title.add_child(BookStyle.label(path.title_key, title_color))
	if Grimoire.can_choose(path):
		var choose := BookStyle.text_button("BOOK_PATH_CHOOSE", BookStyle.GOLD_DARK)
		choose.pressed.connect(func() -> void: Grimoire.choose_path(path))
		title.add_child(choose)
	box.add_child(title)
	var text_color := BookStyle.INK if is_chosen else BookStyle.INK_FAINT
	box.add_child(BookStyle.label(path.description_key, text_color, text_width))
	if level < path.level:
		box.add_child(BookStyle.label(tr("BOOK_PATH_LOCKED") % path.level, BookStyle.INK_FAINT))
	# Am Lesepult lässt sich ein gewählter Pfad gegen seltene Items wechseln.
	if is_chosen and book.opened_at_lectern:
		var cost: Array[String] = []
		for item_id: String in path.respec_cost:
			cost.append("%d %s" % [path.respec_cost[item_id], Inventory.display_name_for(item_id)])
		var change := BookStyle.text_button(tr("BOOK_PATH_CHANGE") % ", ".join(cost),
				BookStyle.GOLD_DARK if Grimoire.can_respec(path.discipline_id, path.level) else BookStyle.INK_FAINT)
		change.disabled = not Grimoire.can_respec(path.discipline_id, path.level)
		change.pressed.connect(func() -> void: Grimoire.respec(path.discipline_id, path.level))
		box.add_child(change)
	return box


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
			# Ein Blatt pro Stufe, abwechselnd nach rechts geneigt.
			draw_rect(Rect2(x + 2, 4, 3, 2), Color("#30624A"))
			draw_rect(Rect2(x + 4, 3, 2, 1), Color("#30624A"))
		if milestone:
			if bloomed:
				# Aufgeblüht: Magenta-Blüte mit goldener Mitte.
				for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
					draw_rect(Rect2(Vector2(x, 6) + offset * 2, Vector2(2, 2)), BookStyle.MAGENTA)
				draw_rect(Rect2(x, 6, 2, 2), BookStyle.GOLD)
			else:
				draw_rect(Rect2(x - 1, 5, 3, 3), BookStyle.MAGENTA if reached else BookStyle.SHEET_SHADOW_DEEP)
