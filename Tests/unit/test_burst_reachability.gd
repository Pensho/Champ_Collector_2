extends GutTest

## Coverage for Scripts/Debug/burst_reachability.gd: the bucket algebra it enforces on top
## of CombinedDamageModifier, candidate enumeration picking the best resolution rather than
## the first, the base/modifier term split, and the two named teams as pinned regression
## fixtures — see that file's header for why those two numbers are the scorer's own output
## rather than a reproduction of the lost hand calc.

const SORCERER = preload("res://Data/Character_Player_Variants/Sorcerer.tres")
const CENTAUR_ARCHIVIST = preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")
const TIDAL_CORSAIR = preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres")
const CULTIST = preload("res://Data/Character_Player_Variants/Cultist.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")
const EMISSARY = preload("res://Data/Character_Player_Variants/Emissary.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")

func _sorcerer_scholar_tactician() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [SORCERER, CENTAUR_ARCHIVIST, TACTICIAN]
	return presets

func _corsair_cultist_warlord() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [TIDAL_CORSAIR, CULTIST, WARLORD]
	return presets

# --- Bucket algebra: same key adds, distinct keys multiply (via the real CombinedDamageModifier) ---

func test_two_contributions_to_the_same_bucket_add_rather_than_compound() -> void:
	var buckets: Dictionary = {}
	BurstReachability._Contribute(buckets, &"Warped", 0.3)
	BurstReachability._Contribute(buckets, &"Warped", 0.1)
	assert_almost_eq(buckets[&"Warped"], 0.4, 0.0001,
		"Two contributions keyed to the same bucket must add, not overwrite or compound")

func test_distinct_buckets_multiply_through_combined_damage_modifier() -> void:
	var buckets: Dictionary = {&"Warped": 0.3, &"Daunting_Strength": 1.0}
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	for key: StringName in buckets:
		modifier.Contribute(key, buckets[key])
	assert_almost_eq(modifier.Product(), 1.3 * 2.0, 0.0001,
		"Distinct buckets must multiply as separate CombinedDamageModifier factors")

# --- Status cap (GameBalance.MAX_STATUS_EFFECTS) ---

func test_status_cap_drops_the_lowest_magnitude_buckets_past_eight() -> void:
	var buckets: Dictionary = {}
	var status_names: Array = Types.Debuff_Type.keys().slice(0, 10)
	for i in status_names.size():
		buckets[StringName(status_names[i])] = 0.1 * float(i + 1)
	var dropped: Array[StringName] = BurstReachability._EnforceStatusCap(buckets)

	assert_eq(dropped.size(), 2, "Two entries over the cap of eight must be dropped")
	assert_eq(buckets.size(), GameBalance.MAX_STATUS_EFFECTS, "Exactly eight statuses must remain")
	assert_true(dropped.has(StringName(status_names[0])),
		"The lowest-magnitude status must be the one dropped")
	assert_true(dropped.has(StringName(status_names[1])),
		"The second-lowest-magnitude status must be the one dropped")

func test_status_cap_leaves_non_status_buckets_untouched() -> void:
	var buckets: Dictionary = {&"Some Skill": 5.0, &"Warped": 0.3}
	var dropped: Array[StringName] = BurstReachability._EnforceStatusCap(buckets)
	assert_eq(dropped.size(), 0, "Two buckets, one of them not a status, must not trip the cap")
	assert_eq(buckets.size(), 2, "Neither bucket should be removed")

# --- Enabler floor ---

func test_enabler_floor_marks_a_team_non_viable_when_unmet() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(
			_sorcerer_scholar_tactician(), 1000)
	assert_false(result.is_viable, "A floor far above any real team's enabler count must exclude it")
	assert_gt(result.enabler_count, 0, "Enabler count must still be reported even when non-viable")

func test_enabler_floor_of_zero_never_excludes() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician(), 0)
	assert_true(result.is_viable, "The default floor of zero must not exclude any team")

func test_enabler_floor_unmet_yields_empty_candidates_and_null_best() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(
			_sorcerer_scholar_tactician(), 1000)
	assert_true(result.candidates.is_empty(),
		"A team below a nonzero floor must not have any candidates appended, not merely be flagged non-viable")
	assert_null(result.Best(), "Best() must be null when the team is excluded by the enabler floor")

# --- Cascade instance bounds ---

func test_cascade_class_magnitude_is_bounded_by_the_per_action_cap() -> void:
	var entry: Dictionary = {"magnitude": 0.5, "class": KitContributionManifest.Contribution_Class.Channel3_Cascade}
	var magnitude: float = BurstReachability._MagnitudeFor(entry)
	assert_almost_eq(magnitude, 0.5 * float(BurstReachability.ASSUMED_UNCAPPED_INSTANCES), 0.0001,
		"A Channel-3-Cascade entry must scale by the assumed instance count")
	assert_lte(BurstReachability.ASSUMED_UNCAPPED_INSTANCES, CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION,
		"The assumed instance count must never exceed the per-action cascade cap")

func test_non_cascade_class_magnitude_passes_through_unscaled() -> void:
	var entry: Dictionary = {"magnitude": 0.36, "class": KitContributionManifest.Contribution_Class.Channel2}
	assert_almost_eq(BurstReachability._MagnitudeFor(entry), 0.36, 0.0001,
		"A Channel-2 entry's magnitude is already a ceiling and must not be scaled")

# --- Candidate enumeration: the best resolution wins, not the first one enumerated ---

func test_best_candidate_is_not_necessarily_the_first_skill_on_the_first_champion() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician())
	assert_false(result.candidates.is_empty(), "The team must produce at least one damaging-skill candidate")
	var best: BurstReachability.CandidateResult = result.Best()
	for candidate in result.candidates:
		assert_gte(best.total_contrast_ratio, candidate.total_contrast_ratio,
			"Best() must be the highest total contrast ratio among all candidates, not index 0")
	assert_true(result.candidates.size() > 1, "A 3-champion team must enumerate more than one damaging skill")

func test_candidates_are_sorted_best_first() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_corsair_cultist_warlord())
	for i in result.candidates.size() - 1:
		assert_gte(result.candidates[i].total_contrast_ratio, result.candidates[i + 1].total_contrast_ratio,
			"Candidates must be sorted by total contrast ratio, best first")

# --- Base term / modifier term separation (Concept_Document.md 1.1.6) ---

func test_base_and_modifier_terms_are_reported_separately_and_do_not_simply_multiply() -> void:
	# Corsairs Reckoning's own Attack 1.3 scaling differs from Boarding Strike's Attack 1.0
	# basic skill (base_term = 1.3 != 1.0), so this candidate actually exercises the
	# nonlinearity Cataclysmic Surge's identical 1.0 base scaling would mask.
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_corsair_cultist_warlord())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Corsairs Reckoning")
	assert_not_null(pinned, "Tidal Corsair's Corsairs Reckoning must be a scored candidate")
	assert_gt(pinned.base_term, 0.0, "Base term must be a positive aggregate ratio")
	assert_gt(pinned.modifier_term, 1.0, "A >1.0x product must contribute more than nothing through mitigation")
	# Skills.MitigatedDamage is nonlinear, so the full ratio is not the terms' product —
	# separating them is what makes 1.1.6's rejection test mechanically checkable.
	assert_ne(pinned.contrast_ratio, pinned.base_term * pinned.modifier_term,
		"The full contrast ratio must not equal the terms' naive product, per the nonlinear mitigation curve")

func test_a_channel_one_only_candidate_has_a_modifier_term_of_one() -> void:
	# Emissary and Thief have no bucket-keyed Channel-2/3 entries reachable by a candidate
	# whose own skill is Channel 1 and grants nothing to a teammate either, so the composed
	# product — and therefore the modifier term run through mitigation — must be neutral.
	var presets: Array[CharacterPreset] = [EMISSARY, THIEF, WARLORD]
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
	var pinned: BurstReachability.CandidateResult = result.Pinned(2, "Shield Slam")
	assert_not_null(pinned, "Warlord's Shield Slam must be a scored candidate")
	assert_almost_eq(pinned.product, 1.0, 0.0001, "No reachable bucket means an untouched 1.0x product")
	assert_almost_eq(pinned.modifier_term, 1.0, 0.0001, "A 1.0x product must contribute nothing through mitigation")

func test_sorcerer_scholar_tactician_bursting_cataclysmic_surge_is_pinned() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Cataclysmic Surge")
	assert_not_null(pinned, "Sorcerer's Cataclysmic Surge must be a scored candidate")
	# Cataclysmic Surge's own Warped bucket (0.3) and Scholar's Expose-Fallacy-granted
	# Opportunist (0.1, anchored to the same Warped debuff Cataclysmic Surge already
	# requires) land in the SAME bucket and add: 0.3 + 0.1 = 0.4. Tactician's Fatal
	# Flaw grants Daunting_Strength unconditionally: a distinct bucket at 1.0. Product:
	# (1 + 0.4) * (1 + 1.0) = 2.8, unchanged by Phase 5 — the Sorcerer's reagent-gated repeat
	# is a separate CombinedDamageModifier instance in the real resolver (never folded into
	# this one; see kit_contribution_manifest.gd's "fold" field), so it lands in
	# repeat_contrast_ratio instead of product.
	assert_almost_eq(pinned.product, 2.8, 0.01,
		"Regression pin: composed product for this team bursting Cataclysmic Surge")
	assert_true(pinned.reagent_assumed,
		"The repeat is assumed reachable even though it does not change this candidate's own product")
	assert_gt(pinned.repeat_contrast_ratio, 0.0,
		"The Sorcerer's reagent-gated repeat must contribute a nonzero, separately-tracked contrast ratio")
	assert_almost_eq(pinned.total_contrast_ratio, pinned.contrast_ratio + pinned.repeat_contrast_ratio, 0.0001,
		"total_contrast_ratio must be exactly contrast_ratio plus the repeat's own contribution")

# --- Manifest override plumbing: a modeled kit change reaches the scorer without editing
# the real manifest or the scorer's own logic (used by Tests/manual/prescription_sweep.gd) ---

func test_a_modified_manifest_changes_scoring_without_touching_the_real_one() -> void:
	var presets: Array[CharacterPreset] = [EMISSARY, THIEF, WARLORD]
	var baseline: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
	var baseline_pinned: BurstReachability.CandidateResult = baseline.Pinned(2, "Shield Slam")
	assert_almost_eq(baseline_pinned.product, 1.0, 0.0001,
		"Sanity: this team's product is neutral against the real manifest")

	var modified_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var warlord_entry: Dictionary = modified_manifest[Types.Role.Warlord]
	warlord_entry["skills"][0]["bucket_key"] = "Invented Test Factor"
	warlord_entry["skills"][0]["magnitude"] = 0.5
	warlord_entry["skills"][0]["class"] = KitContributionManifest.Contribution_Class.Channel2

	var modeled: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets, 0, modified_manifest)
	var modeled_pinned: BurstReachability.CandidateResult = modeled.Pinned(2, "Shield Slam")
	assert_almost_eq(modeled_pinned.product, 1.5, 0.0001,
		"An invented Channel2 entry on the modified copy must reach the scorer's output")
	assert_almost_eq(
			BurstReachability.ScoreTeam(presets).Pinned(2, "Shield Slam").product, 1.0, 0.0001,
			"The real MANIFEST must be unaffected by scoring against a duplicated, modified copy")


func test_tidal_corsair_cultist_warlord_bursting_corsairs_reckoning_is_pinned() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_corsair_cultist_warlord())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Corsairs Reckoning")
	assert_not_null(pinned, "Tidal Corsair's Corsairs Reckoning must be a scored candidate")
	# Wrangle the Sea's trait_resource ceiling (1.8) is the only reachable bucket: Chosen
	# Vessel is Cultist's OWN passive, gated to Cultist's own casts, and Cultist is not the
	# caster in this candidate, so it contributes nothing here. Product: 1 + 1.8 = 2.8.
	assert_almost_eq(pinned.product, 2.8, 0.01,
		"Regression pin: composed product for this team bursting Corsairs Reckoning")
