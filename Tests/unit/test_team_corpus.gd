extends GutTest

## Coverage for Scripts/Debug/team_corpus.gd: the row shape the scorer relies on (exactly
## three presets, a valid tier, an optional pinned resolution) and that every row is
## actually scoreable by BurstReachability.ScoreTeam — a corpus row that crashes the scorer
## defeats the point of a pluggable input.

func test_every_row_has_exactly_three_presets() -> void:
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		var presets: Array = row.get("presets", [])
		assert_eq(presets.size(), 3, "Every corpus row must carry exactly three presets")

func test_every_row_has_a_valid_tier() -> void:
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		assert_true(TeamCorpus.Tier.values().has(row.get("tier", -1)),
			"Every corpus row's tier must be one of TeamCorpus.Tier's members")

func test_every_row_is_marked_provisional() -> void:
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		assert_true(row.get("provisional", false),
			"Every row in PROVISIONAL_ROWS must be marked provisional: these are seeded " +
			"from a full-roster sweep, not a curated set, and must never be presented as findings")

func test_every_row_scores_without_error() -> void:
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		var presets: Array[CharacterPreset] = []
		for preset in row["presets"]:
			presets.append(preset)
		var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
		assert_false(result.candidates.is_empty(),
			"Every corpus row must produce at least one scored candidate: %s" % [row["presets"]])

func test_pinned_rows_resolve_to_the_named_candidate() -> void:
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		var pinned: Dictionary = row.get("pinned", {})
		if(pinned.is_empty()):
			continue
		var presets: Array[CharacterPreset] = []
		for preset in row["presets"]:
			presets.append(preset)
		var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
		var candidate: BurstReachability.CandidateResult = result.Pinned(
				pinned["caster_index"], pinned["skill_name"])
		assert_not_null(candidate,
			"A row's pinned resolution must actually be a scored candidate: %s" % [pinned])

func test_the_two_hand_computed_regression_teams_are_present_and_pinned() -> void:
	var found_cataclysmic_surge: bool = false
	var found_corsairs_reckoning: bool = false
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		var pinned: Dictionary = row.get("pinned", {})
		if("Cataclysmic Surge" == pinned.get("skill_name", "")):
			found_cataclysmic_surge = true
		if("Corsairs Reckoning" == pinned.get("skill_name", "") and TeamCorpus.Tier.Intent == row.get("tier", -1)):
			found_corsairs_reckoning = true
	assert_true(found_cataclysmic_surge,
		"The Sorcerer/Scholar/Tactician regression fixture must be present in the corpus")
	assert_true(found_corsairs_reckoning,
		"The Tidal Corsair/Cultist/Warlord regression fixture must be present in the corpus")
