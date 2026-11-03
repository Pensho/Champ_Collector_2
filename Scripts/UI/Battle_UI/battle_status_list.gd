class_name BattleStatusList extends RefCounted

## The statuses currently shown on each combatant, kept exactly as displayed so the battle
## menu lists the same text as the status-icon tooltips. Keyed by resolver status ID.

class Entry:
	var character_ID: int = -1
	var icon: Texture2D
	var title: String = ""
	var description: String = ""
	var duration: int = 0
	var stacks: int = 0

class Section:
	var character_name: String = ""
	var entries: Array[Entry] = []

var _entries: Dictionary[int, Entry] = {}

func Record(
		p_status_ID: int,
		p_character_ID: int,
		p_icon: Texture2D,
		p_title: String,
		p_description: String,
		p_duration: int,
		p_stacks: int) -> void:
	var entry: Entry = _entries.get(p_status_ID, Entry.new())
	entry.character_ID = p_character_ID
	entry.icon = p_icon
	entry.title = p_title
	entry.description = p_description
	entry.duration = p_duration
	entry.stacks = p_stacks
	_entries[p_status_ID] = entry

func SetDuration(p_status_ID: int, p_duration: int) -> void:
	if(_entries.has(p_status_ID)):
		_entries[p_status_ID].duration = p_duration

func Remove(p_status_ID: int) -> void:
	_entries.erase(p_status_ID)

func ClearCharacter(p_character_ID: int) -> void:
	for status_ID: int in _entries.keys():
		if(_entries[status_ID].character_ID == p_character_ID):
			_entries.erase(status_ID)

## One section per character in p_character_names that holds a status, in that dictionary's
## order; a character left out (e.g. a defeated one) gets no section.
func Sections(p_character_names: Dictionary[int, String]) -> Array[Section]:
	var sections: Array[Section] = []
	for character_ID: int in p_character_names.keys():
		var section: Section = Section.new()
		section.character_name = p_character_names[character_ID]
		for entry: Entry in _entries.values():
			if(entry.character_ID == character_ID):
				section.entries.append(entry)
		if(not section.entries.is_empty()):
			sections.append(section)
	return sections
