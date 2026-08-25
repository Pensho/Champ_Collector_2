class_name ProfileDetailsPanel extends Control

@export var _empty_label: Label
@export var _stats_container: Control
@export var _highest_difficulty_label: Label
@export var _highest_character_level_label: Label
@export var _character_count_label: Label
@export var _unique_characters_label: Label
@export var _silver_label: Label
@export var _supplies_label: Label

func SetProfile(p_meta: Dictionary) -> void:
	if (p_meta.is_empty()):
		Clear()
		return

	_empty_label.hide()
	_stats_container.show()
	_highest_difficulty_label.text = _FormatStat(
		p_meta, "highest_difficulty", "%s / " + str(Game_Balance.MAX_DIFFICULTY))
	_highest_character_level_label.text = _FormatStat(
		p_meta, "highest_character_level", "Lv %s")
	_character_count_label.text = _FormatCount(
		p_meta, "character_count", "character_capacity")
	_unique_characters_label.text = _FormatStat(p_meta, "unique_characters", "%s")
	_silver_label.text = _FormatStat(p_meta, "silver", "%s")
	_supplies_label.text = _FormatStat(p_meta, "supplies", "%s")

func Clear() -> void:
	_empty_label.show()
	_stats_container.hide()

func _FormatStat(p_meta: Dictionary, p_key: String, p_format: String) -> String:
	if (not p_meta.has(p_key)):
		return "—"
	return p_format % str(int(p_meta[p_key]))

func _FormatCount(p_meta: Dictionary, p_count_key: String, p_capacity_key: String) -> String:
	if (not p_meta.has(p_count_key) or not p_meta.has(p_capacity_key)):
		return "—"
	return str(int(p_meta[p_count_key])) + " / " + str(int(p_meta[p_capacity_key]))
