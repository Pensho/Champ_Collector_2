extends GutTest

## Not part of the default suite (Tests/unit/ only) — run explicitly:
##   Tests/run_tests.sh -gtest=res://Tests/manual/team_corpus_sweep.gd -gexit
##
## Enumerates every C(20,3) = 1140 team through BurstReachability.ScoreTeam and reports:
## the top and bottom teams by contrast ratio, the scored team-corpus table, and the
## combined-modifier-product distribution (median, 90th percentile, max) with the ceiling
## team's full bucket decomposition. A bare `-s` SceneTree script cannot do any of this: any
## script whose static dependency graph reaches Character.new() (which ScoreTeam calls)
## fails, because Character's Attribute reference to the "main" autoload singleton cannot
## resolve before a custom main-loop script's own compile step runs — Character.new() then
## permanently returns "Nonexistent function 'new' in base 'GDScript'" for the rest of the
## process. Running through GUT sidesteps this: it is the same entry path already proven to
## exercise Character correctly (test_burst_reachability_live.gd).
##
## A useful check to re-run after kits are reworked, to see whether anything in the roster's
## distribution moved unexpectedly.
##
## PRESET_PATHS is the full known roster, not hand-curated to one preset per Role: several
## presets can field the same Role (same trait, same three skills — e.g. Centaur_Lancer.tres
## and Knight.tres both field Lancer, per kit_contribution_manifest.gd's Lancer entry), and
## burst reachability is a property of the Role's kit, not of the preset fielding it. Listing
## every preset here and reducing through TeamSweep.DedupeByRole below, rather than curating
## the list by hand, means a future preset added to the roster that shares an existing Role is
## excluded from the sweep automatically instead of needing this list edited again.

const PRESET_PATHS: Array[String] = [
	"res://Data/Character_Player_Variants/Alchemist.tres",
	"res://Data/Character_Player_Variants/Appraiser.tres",
	"res://Data/Character_Player_Variants/Architect.tres",
	"res://Data/Character_Player_Variants/Bar_Brawler.tres",
	"res://Data/Character_Player_Variants/Bloodmage.tres",
	"res://Data/Character_Player_Variants/Centaur_Archivist.tres",
	"res://Data/Character_Player_Variants/Centaur_Lancer.tres",
	"res://Data/Character_Player_Variants/Chronophage.tres",
	"res://Data/Character_Player_Variants/Cultist.tres",
	"res://Data/Character_Player_Variants/Diviner.tres",
	"res://Data/Character_Player_Variants/Emissary.tres",
	"res://Data/Character_Player_Variants/Herald_of_the_loom.tres",
	"res://Data/Character_Player_Variants/Jester.tres",
	"res://Data/Character_Player_Variants/Knight.tres",
	"res://Data/Character_Player_Variants/Plague_Doctor.tres",
	"res://Data/Character_Player_Variants/Sorcerer.tres",
	"res://Data/Character_Player_Variants/Symbiote.tres",
	"res://Data/Character_Player_Variants/Tactician.tres",
	"res://Data/Character_Player_Variants/Thief.tres",
	"res://Data/Character_Player_Variants/Tidal_Corsair.tres",
	"res://Data/Character_Player_Variants/Warlord.tres",
]

var _rows: Array[Dictionary] = []


func before_all() -> void:
	var presets: Array[CharacterPreset] = []
	for path in PRESET_PATHS:
		presets.append(load(path))
	_rows = TeamSweep.ScoreAllTeams(TeamSweep.DedupeByRole(presets))


func test_sweep_prints_top_and_bottom_teams_by_contrast_ratio() -> void:
	var expected_team_count: int = 1140  # C(20,3)
	assert_eq(_rows.size(), expected_team_count, "Every 3-preset combination must produce a scored team")

	var by_ratio: Array[Dictionary] = _rows.duplicate()
	by_ratio.sort_custom(func(a, b): return a["contrast_ratio"] > b["contrast_ratio"])
	gut.p("=== %d teams scored ===" % by_ratio.size())
	gut.p("--- Top 10 by contrast ratio ---")
	for i in mini(10, by_ratio.size()):
		gut.p(by_ratio[i])
	gut.p("--- Bottom 10 by contrast ratio ---")
	for i in mini(10, by_ratio.size()):
		gut.p(by_ratio[by_ratio.size() - 1 - i])


## Prints the team-corpus rows (Scripts/Debug/team_corpus.gd) scored through the same
## resolution the sweep uses — a pinned row resolves to its named candidate, an unpinned row
## to its best.
func test_corpus_table_prints_every_row_scored() -> void:
	gut.p("=== Team corpus (%d rows) ===" % TeamCorpus.PROVISIONAL_ROWS.size())
	for row: Dictionary in TeamCorpus.PROVISIONAL_ROWS:
		var presets: Array[CharacterPreset] = []
		for preset in row["presets"]:
			presets.append(preset)
		var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
		var pinned: Dictionary = row.get("pinned", {})
		var candidate: BurstReachability.CandidateResult = (
				result.Pinned(pinned["caster_index"], pinned["skill_name"]) if not pinned.is_empty()
				else result.Best())
		assert_not_null(candidate, "Every corpus row must produce a scored resolution: %s" % [row["presets"]])

		var names: Array = []
		for preset in row["presets"]:
			names.append((preset as CharacterPreset).resource_path.get_file())
		gut.p(("%s  tier=%s  caster=%d skill=%s  product=%.2fx ratio=%.2fx " +
				"(base=%.2fx mod=%.2fx)  keys=%d enablers=%d reagent_assumed=%s")
				% [names, TeamCorpus.Tier.keys()[row["tier"]], candidate.caster_index, candidate.skill_name,
				candidate.product, candidate.contrast_ratio, candidate.base_term, candidate.modifier_term,
				candidate.distinct_key_count, candidate.enabler_count, candidate.reagent_assumed])


## The two outputs that matter: the achievable-product distribution across the full roster,
## and the single best team's bucket decomposition. Neither a ranked list of all 1140 teams
## nor any row of it is acted on here — this is a shape and a bound.
func test_full_roster_sweep_reports_distribution_and_ceiling() -> void:
	var expected_team_count: int = 1140  # C(20,3)
	assert_eq(_rows.size(), expected_team_count, "Every 3-preset combination must produce a scored team")

	var products: Array[float] = []
	for row: Dictionary in _rows:
		products.append(row["product"])
	products.sort()

	var median: float = TeamSweep.Percentile(products, 0.5)
	var ninetieth: float = TeamSweep.Percentile(products, 0.9)
	var maximum: float = products[products.size() - 1]

	gut.p("=== Combined-modifier product distribution across all %d teams ===" % _rows.size())
	gut.p("median=%.2fx  90th percentile=%.2fx  max=%.2fx" % [median, ninetieth, maximum])
	assert_gte(ninetieth, median, "The 90th percentile must be at or above the median")
	assert_gte(maximum, ninetieth, "The maximum must be at or above the 90th percentile")

	var ceiling_row: Dictionary = _rows[0]
	for row: Dictionary in _rows:
		if(row["product"] > ceiling_row["product"]):
			ceiling_row = row

	gut.p("--- Ceiling team ---")
	gut.p("%s  caster=%d skill=%s  product=%.2fx ratio=%.2fx  buckets=%s"
			% [ceiling_row["names"], ceiling_row["caster_index"], ceiling_row["skill_name"],
			ceiling_row["product"], ceiling_row["contrast_ratio"], ceiling_row["buckets"]])
	assert_almost_eq(ceiling_row["product"], maximum, 0.0001,
			"The reported ceiling row must be the same team the distribution's max came from")
	assert_false(ceiling_row["buckets"].is_empty(),
			"The roster's ceiling team must reach at least one composed bucket")


## Concept_Document.md 1.1's discrimination requirement, Plan_Itemization_Channels.md Phase 5:
## a large-magnitude factor that is available to every champion regardless of kit lifts the
## median as much as the ceiling and makes the roster less discriminating even while raising
## its numbers (see the plan's "What Phase 5 requires of any new factor"). The target outcome
## of the Sorcerer/Alchemist rework is a second top-decile pairing, distinct from Tidal
## Corsair's Wrangle the Sea composed with Tactician's Daunting Strength grant — not a uniform
## lift, AND actually driven by the Sorcerer's own repeat, not merely by the Sorcerer riding
## along as an inert third slot on a team whose ceiling is really Tidal Corsair or Architect
## (the same failure mode the corpus's existing "equally inert third slot" rows already record
## for Bar Brawler/Symbiote next to Tidal Corsair + Tactician).
##
## Ranked by _rows's own total_contrast_ratio: BurstReachability.ScoreTeam's Best() now ranks
## candidates by total_contrast_ratio itself (contrast_ratio plus a separate-instance Channel-3
## repeat), a bug fix made alongside this phase — ranking by contrast_ratio alone silently
## zeroed out every Channel-3 repeat mechanic's ability to win Best() at all, since a repeat can
## never be folded into the single CombinedDamageModifier product/contrast_ratio represent (see
## burst_reachability.gd's header). _rows's Best()-derived rows are therefore already the right
## thing to rank by here.
func test_full_roster_sweep_finds_a_second_distinct_ceiling_pairing() -> void:
	var by_total: Array[Dictionary] = _rows.duplicate()
	by_total.sort_custom(func(a, b): return a["total_contrast_ratio"] > b["total_contrast_ratio"])
	var top_decile_count: int = maxi(1, int(ceil(0.1 * by_total.size())))

	var found_sorcerer_repeat_pairing: bool = false
	var found_tidal_tactician: bool = false
	gut.p("=== Top decile by best-candidate total contrast ratio (%d teams) ===" % top_decile_count)
	for i in top_decile_count:
		var row: Dictionary = by_total[i]
		var names: Array = row["names"]
		var is_sorcerer_repeat: bool = (Types.Role.Sorcerer == row["caster_role"] and names.has("Alchemist.tres")
				and row["repeat_contrast_ratio"] > 0.0)
		var has_tidal_tactician: bool = names.has("Tidal_Corsair.tres") and names.has("Tactician.tres")
		found_sorcerer_repeat_pairing = found_sorcerer_repeat_pairing or is_sorcerer_repeat
		found_tidal_tactician = found_tidal_tactician or has_tidal_tactician
		# Role.find_key(), not Role.keys()[value]: Types.Role's members carry explicit,
		# non-sequential integer values (a gap at 1, Thief=2), so keys()[value] silently
		# mis-indexes past that gap.
		gut.p(("%s  caster_role=%s skill=%s  total_ratio=%.2fx (base=%.2fx repeat=%.2fx)  " +
				"reagent_assumed=%s  sorcerer_repeat_driven=%s  tidal+tactician=%s")
				% [names, Types.Role.find_key(row["caster_role"]), row["skill_name"], row["total_contrast_ratio"],
				row["contrast_ratio"], row["repeat_contrast_ratio"], row["reagent_assumed"], is_sorcerer_repeat,
				has_tidal_tactician])

	gut.p("--- Pairing summary ---")
	gut.p(("Sorcerer-repeat-driven Alchemist pairing reaches top decile: %s   " +
			"Tidal Corsair+Tactician reaches top decile: %s")
			% [found_sorcerer_repeat_pairing, found_tidal_tactician])
	var expected_team_count: int = 1140  # C(20,3)
	assert_eq(by_total.size(), expected_team_count, "Every 3-preset combination must produce a scored team")
	assert_true(found_tidal_tactician,
			"Sanity: the pre-existing Tidal Corsair+Tactician pairing must still reach the top decile")
	# Whether a Sorcerer-repeat-driven pairing ALSO reaches the top decile is recorded as a
	# finding, per the plan's own fallback ("recording the blind spot instead of closing it...
	# leaves the claim unverified") — not asserted, since whether the Sorcerer's repeat is tuned
	# strongly enough to actually contend for the roster's ceiling is a balance question for the
	# plan owner, not something this scorer should force to pass.
