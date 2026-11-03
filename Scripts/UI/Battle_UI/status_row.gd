class_name StatusRow extends HBoxContainer

@export var _icon: TextureRect
@export var _title_label: Label
@export var _remaining_label: Label
@export var _description_label: Label

func SetEntry(p_entry: BattleStatusList.Entry) -> void:
	_icon.texture = p_entry.icon
	_title_label.text = p_entry.title
	_remaining_label.text = RemainingText(p_entry.duration, p_entry.stacks)
	_description_label.text = p_entry.description

static func RemainingText(p_duration: int, p_stacks: int) -> String:
	var parts: PackedStringArray = []
	if(p_stacks > 0):
		parts.append("%d stacks" % p_stacks if p_stacks > 1 else "1 stack")
	if(p_duration > 0):
		parts.append("%d turns" % p_duration if p_duration > 1 else "1 turn")
	return ", ".join(parts)
