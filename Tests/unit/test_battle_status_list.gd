extends GutTest

var status_list: BattleStatusList

func before_each() -> void:
	status_list = BattleStatusList.new()

func _Names(p_pairs: Array) -> Dictionary[int, String]:
	var names: Dictionary[int, String] = {}
	for pair: Array in p_pairs:
		names[pair[0]] = pair[1]
	return names

func test_sections_follow_name_order_and_skip_characters_without_statuses() -> void:
	status_list.Record(10, 3, null, "Burn", "Burns.", 2, 0)
	status_list.Record(11, 0, null, "Haste", "Faster.", 2, 0)

	var sections: Array[BattleStatusList.Section] = status_list.Sections(
			_Names([[0, "Ally"], [1, "Idle Ally"], [3, "Enemy"]]))

	assert_eq(sections.size(), 2, "Only characters holding a status get a section")
	assert_eq(sections[0].character_name, "Ally")
	assert_eq(sections[1].character_name, "Enemy")

func test_character_missing_from_names_gets_no_section() -> void:
	status_list.Record(10, 4, null, "Burn", "Burns.", 2, 0)

	assert_eq(status_list.Sections(_Names([[0, "Ally"]])).size(), 0,
			"A defeated character left out of the names is not listed")

func test_entries_keep_application_order_within_a_character() -> void:
	status_list.Record(1, 0, null, "Haste", "Faster.", 2, 0)
	status_list.Record(2, 0, null, "Burn", "Burns.", 3, 0)

	var entries: Array[BattleStatusList.Entry] = status_list.Sections(_Names([[0, "Ally"]]))[0].entries

	assert_eq(entries.size(), 2)
	assert_eq(entries[0].title, "Haste")
	assert_eq(entries[1].title, "Burn")

func test_recording_an_existing_status_updates_it_in_place() -> void:
	status_list.Record(1, 0, null, "Poison", "1 stack.", 2, 1)
	status_list.Record(2, 0, null, "Haste", "Faster.", 2, 0)
	status_list.Record(1, 0, null, "Poison", "2 stacks.", 3, 2)

	var entries: Array[BattleStatusList.Entry] = status_list.Sections(_Names([[0, "Ally"]]))[0].entries

	assert_eq(entries.size(), 2)
	assert_eq(entries[0].description, "2 stacks.")
	assert_eq(entries[0].duration, 3)
	assert_eq(entries[0].stacks, 2)

func test_set_duration_updates_turns_left() -> void:
	status_list.Record(1, 0, null, "Haste", "Faster.", 2, 0)
	status_list.SetDuration(1, 1)

	assert_eq(status_list.Sections(_Names([[0, "Ally"]]))[0].entries[0].duration, 1)

func test_remove_drops_only_that_status() -> void:
	status_list.Record(1, 0, null, "Haste", "Faster.", 2, 0)
	status_list.Record(2, 0, null, "Burn", "Burns.", 2, 0)
	status_list.Remove(1)

	var entries: Array[BattleStatusList.Entry] = status_list.Sections(_Names([[0, "Ally"]]))[0].entries

	assert_eq(entries.size(), 1)
	assert_eq(entries[0].title, "Burn")

func test_clear_character_drops_only_that_characters_statuses() -> void:
	status_list.Record(1, 0, null, "Haste", "Faster.", 2, 0)
	status_list.Record(2, 3, null, "Burn", "Burns.", 2, 0)
	status_list.ClearCharacter(0)

	var sections: Array[BattleStatusList.Section] = status_list.Sections(_Names([[0, "Ally"], [3, "Enemy"]]))

	assert_eq(sections.size(), 1)
	assert_eq(sections[0].character_name, "Enemy")
