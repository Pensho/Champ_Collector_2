class_name CharacterStatusSection extends VBoxContainer

@export var _name_label: Label
@export var _rows: Array[StatusRow]

func SetSection(p_section: BattleStatusList.Section) -> void:
	_name_label.text = p_section.character_name
	for index in _rows.size():
		if(index < p_section.entries.size()):
			_rows[index].SetEntry(p_section.entries[index])
			_rows[index].show()
		else:
			_rows[index].hide()
