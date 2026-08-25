extends GutTest

func _make_panel() -> ProfileDetailsPanel:
	var panel: ProfileDetailsPanel = ProfileDetailsPanel.new()
	panel._empty_label = Label.new()
	panel._stats_container = Control.new()
	panel._highest_difficulty_label = Label.new()
	panel._highest_character_level_label = Label.new()
	panel._character_count_label = Label.new()
	panel._unique_characters_label = Label.new()
	panel._silver_label = Label.new()
	panel._supplies_label = Label.new()
	add_child_autoqfree(panel)
	return panel

func _full_meta() -> Dictionary:
	return {
		"highest_difficulty": 12,
		"highest_character_level": 34,
		"character_count": 17,
		"character_capacity": 50,
		"unique_characters": 9,
		"silver": 12450,
		"supplies": 38,
	}

func test_set_profile_with_full_meta_fills_every_row() -> void:
	var panel: ProfileDetailsPanel = _make_panel()
	panel.SetProfile(_full_meta())

	assert_false(panel._empty_label.visible, "The empty-state label should hide when meta data is present")
	assert_true(panel._stats_container.visible, "The stats container should show when meta data is present")
	assert_eq(panel._highest_difficulty_label.text, "12 / " + str(Game_Balance.MAX_DIFFICULTY))
	assert_eq(panel._highest_character_level_label.text, "Lv 34")
	assert_eq(panel._character_count_label.text, "17 / 50")
	assert_eq(panel._unique_characters_label.text, "9")
	assert_eq(panel._silver_label.text, "12450")
	assert_eq(panel._supplies_label.text, "38")

func test_set_profile_with_missing_keys_renders_dash() -> void:
	var panel: ProfileDetailsPanel = _make_panel()
	# Pre-rework saves only carry profile_name/saved_at, none of the newer stat keys.
	panel.SetProfile({"profile_name": "Old Save", "saved_at": "2026-01-01T00:00:00"})

	assert_eq(panel._highest_difficulty_label.text, "—")
	assert_eq(panel._highest_character_level_label.text, "—")
	assert_eq(panel._character_count_label.text, "—")
	assert_eq(panel._unique_characters_label.text, "—")
	assert_eq(panel._silver_label.text, "—")
	assert_eq(panel._supplies_label.text, "—")

func test_clear_shows_empty_label_and_hides_stats() -> void:
	var panel: ProfileDetailsPanel = _make_panel()
	panel.SetProfile(_full_meta())
	panel.Clear()

	assert_true(panel._empty_label.visible)
	assert_false(panel._stats_container.visible)
