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
const CHRONOPHAGE = preload("res://Data/Character_Player_Variants/Chronophage.tres")
const ARCHITECT = preload("res://Data/Character_Player_Variants/Architect.tres")

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

func test_best_ignores_a_large_sustained_payload() -> void:
	# A multi-turn total is not comparable to one action, so a large sustained_ticks payload must
	# not outrank a stronger single-action burst.
	var presets: Array[CharacterPreset] = [EMISSARY, THIEF, WARLORD]
	var modified_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)

	var strong_single_action_entry: Dictionary = modified_manifest[Types.Role.Warlord]["skills"][0]
	strong_single_action_entry["bucket_key"] = "Strong Single-Action Factor"
	strong_single_action_entry["magnitude"] = 2.0
	strong_single_action_entry["class"] = KitContributionManifest.Contribution_Class.Channel2

	var sustained_entry: Dictionary = modified_manifest[Types.Role.Thief]["skills"][1]
	sustained_entry["class"] = KitContributionManifest.Contribution_Class.Channel1
	sustained_entry["gated_bonus"] = {"bucket_key": "", "magnitude": 0.0,
			"class": KitContributionManifest.Contribution_Class.Channel1, "fold": "sustained_ticks",
			"gate": &"debuff_count", "instances": 16}

	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets, 0, modified_manifest)
	var strong_single_action: BurstReachability.CandidateResult = result.Pinned(2, "Shield Slam")
	var sustained_driven: BurstReachability.CandidateResult = result.Pinned(1, "Pierce weakness")
	assert_not_null(strong_single_action, "The modified Warlord entry must still be a scored candidate")
	assert_not_null(sustained_driven, "The modified Thief entry must still be a scored candidate")
	assert_gt(strong_single_action.total_contrast_ratio, sustained_driven.total_contrast_ratio,
		"Sanity: the single-action candidate must win on total_contrast_ratio alone")
	assert_gt(sustained_driven.sustained_contrast_ratio, strong_single_action.total_contrast_ratio,
		"Sanity: the sustained payload must be larger than the single action")
	assert_eq(result.Best(), strong_single_action,
		"Best() must pick the stronger single action, not the sustained payload")

# --- Base term / modifier term separation (Concept_Document.md 1.1.6) ---

func test_base_and_modifier_terms_are_reported_separately_and_do_not_simply_multiply() -> void:
	# Mitigation itself is linear in the scaled aggregate for a FIXED effective Defence
	# (Skills.MitigatedDamageUnrounded's mitigation_factor depends only on Defence), so the
	# terms' naive product only diverges from the full ratio when burst and baseline resolve
	# against different effective Defence. Pierce weakness's defence_ignore multiple (2.5x
	# the Thief's Between the Plates rate) does that against the basic skill's own 1.0x —
	# Emissary's team-reach Sanction bucket also gives this candidate a >1.0x product, so
	# both terms are exercised at once.
	var presets: Array[CharacterPreset] = [THIEF, EMISSARY, WARLORD]
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Pierce weakness")
	assert_not_null(pinned, "Thief's Pierce weakness must be a scored candidate")
	assert_gt(pinned.base_term, 0.0, "Base term must be a positive aggregate ratio")
	assert_gt(pinned.modifier_term, 1.0, "A >1.0x product must contribute more than nothing through mitigation")
	# Separating the terms is what makes 1.1.6's rejection test mechanically checkable, and a
	# defence-ignore difference is a real, non-floating-point-noise source of divergence.
	assert_ne(pinned.contrast_ratio, pinned.base_term * pinned.modifier_term,
		"The full contrast ratio must not equal the terms' naive product when burst and baseline " +
		"resolve against different effective Defence")

func test_a_channel_one_only_candidate_has_a_modifier_term_of_one() -> void:
	# Chronophage and Thief have no bucket-keyed Channel-2/3 entries reachable by a candidate
	# whose own skill is Channel 1 and grants nothing to a teammate either, so the composed
	# product — and therefore the modifier term run through mitigation — must be neutral.
	# (Emissary is not used here: Levied Sanction's Sanction debuff is now an exported bucket
	# reachable by any teammate's attack, per Role_Kit_Design.md section 9.7.)
	var presets: Array[CharacterPreset] = [CHRONOPHAGE, THIEF, WARLORD]
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets)
	var pinned: BurstReachability.CandidateResult = result.Pinned(2, "Shield Slam")
	assert_not_null(pinned, "Warlord's Shield Slam must be a scored candidate")
	assert_almost_eq(pinned.product, 1.0, 0.0001, "No reachable bucket means an untouched 1.0x product")
	assert_almost_eq(pinned.modifier_term, 1.0, 0.0001, "A 1.0x product must contribute nothing through mitigation")

func test_sorcerer_scholar_tactician_bursting_cataclysm_is_pinned() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Cataclysm")
	assert_not_null(pinned, "Sorcerer's Cataclysm must be a scored candidate")
	# Cataclysm's own Warped bucket (0.3) and Scholar's Expose-Fallacy-granted
	# Opportunist (0.1, anchored to the same Warped debuff Cataclysm already
	# requires) land in the SAME bucket and add: 0.3 + 0.1 = 0.4. Tactician's Fatal
	# Flaw grants Daunting_Strength unconditionally: a distinct bucket at 1.0. Product:
	# Opportunist also adds its own factor for Confound and Suppress, the Scholar's other debuff
	# types: (1 + 0.4) * 1.1 * 1.1 * (1 + 1.0) = 3.388 — the Sorcerer's Echoes are separate
	# CombinedDamageModifier instances in the real resolver (never folded into this one;
	# see kit_contribution_manifest.gd's "fold" field), so they land in
	# repeat_contrast_ratio instead of product.
	assert_almost_eq(pinned.product, 3.388, 0.01,
		"Regression pin: composed product for this team bursting Cataclysm")
	assert_true(pinned.assumed_gates.has(&"instability_held"),
		"The Echoes are assumed reachable even though they do not change this candidate's own product")
	assert_gt(pinned.repeat_contrast_ratio, 0.0,
		"The Sorcerer's Echoes must contribute a nonzero, separately-tracked contrast ratio")
	assert_almost_eq(pinned.total_contrast_ratio, pinned.contrast_ratio + pinned.repeat_contrast_ratio, 0.0001,
		"total_contrast_ratio must be exactly contrast_ratio plus the Echoes' own contribution")

func test_sorcerer_arc_lash_never_echoes() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Arc Lash")
	assert_not_null(pinned, "Sorcerer's Arc Lash must be a scored candidate")
	assert_almost_eq(pinned.repeat_contrast_ratio, 0.0, 0.0001, "Only Cataclysm Echoes with Instability")

# --- Manifest override plumbing: a modeled kit change reaches the scorer without editing
# the real manifest or the scorer's own logic (used by Tests/manual/prescription_sweep.gd) ---

func test_a_modified_manifest_changes_scoring_without_touching_the_real_one() -> void:
	var presets: Array[CharacterPreset] = [CHRONOPHAGE, THIEF, WARLORD]
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

func test_cultist_devotion_gated_bonus_multiplies_with_the_per_cast_trait_resource_bucket() -> void:
	# Devotion (Role_Kit_Design.md section 9.8) is a self-reach gated_bonus on Chosen Vessel's
	# own manifest entry, landing in a distinct ChosenVesselTrait bucket from both the shared
	# trait_resource key (Chosen Vessel's per-cast bonus) and Devour Blessing's own "Devour
	# Blessing" bucket — three distinct buckets multiply: (1+0.30) * (1+0.20) * (1+0.25) = 1.95.
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_corsair_cultist_warlord())
	var pinned: BurstReachability.CandidateResult = result.Pinned(1, "Devour Blessing")
	assert_not_null(pinned, "Cultist's Devour Blessing must be a scored candidate")
	assert_true(pinned.assumed_gates.has(&"a Vessel has died"),
		"Devotion's gate must be surfaced on assumed_gates")
	assert_almost_eq(pinned.product, 1.95, 0.01,
		"Chosen Vessel's trait_resource, Devotion, and Devour Blessing buckets must all multiply")

# --- Channel-1 attribute-buff crediting (_ContributeGrantedAttributeBuffs) ---

func test_granted_attribute_buff_reaches_every_teammate_from_a_team_reach_passive() -> void:
	var presets: Array[CharacterPreset] = [TACTICIAN, EMISSARY, THIEF]
	var characters: Array[Character] = []
	for i in presets.size():
		var character: Character = Character.new()
		character.InstantiateNew(presets[i], i)
		characters.append(character)

	var bonus_for_teammate: Dictionary = BurstReachability._ContributeGrantedAttributeBuffs(
			characters, 1, KitContributionManifest.MANIFEST)
	var fractions_for_teammate: Dictionary = bonus_for_teammate.get("fractions", {})

	assert_almost_eq(fractions_for_teammate.get(Types.Attribute.Attack, 0.0), 0.3, 0.0001,
		"Tactician's Plan ahead (team-reach passive) must credit Empower's +30% Attack to a teammate")

func test_scholars_field_of_study_amplifies_a_teammates_granted_attribute_buff() -> void:
	# Role_Kit_Design.md 9.14, closing section 11's open gap: the scorer credits granted
	# attribute buffs but previously had no way to amplify them. Tactician's Plan ahead
	# grants +30% Attack (team reach); the Scholar's Field of Study adds 0.11 (Legendary)
	# percentage points on top: 0.3 + 0.11 = 0.41.
	var presets: Array[CharacterPreset] = [TACTICIAN, CENTAUR_ARCHIVIST, THIEF]
	var characters: Array[Character] = []
	for i in presets.size():
		var character: Character = Character.new()
		character.InstantiateNew(presets[i], i)
		characters.append(character)

	var bonus_for_teammate: Dictionary = BurstReachability._ContributeGrantedAttributeBuffs(
			characters, 2, KitContributionManifest.MANIFEST)
	var fractions_for_teammate: Dictionary = bonus_for_teammate.get("fractions", {})

	assert_almost_eq(fractions_for_teammate.get(Types.Attribute.Attack, 0.0), 0.41, 0.0001,
		"Field of Study must add its own percentage points onto Plan ahead's granted fraction")

# --- gated_bonus instance curve (_MultiInstanceContrastRatio, _GatedContrastRatios) ---

func test_multi_instance_contrast_ratio_compounds_across_declared_instances() -> void:
	# Role_Kit_Design.md 9.3's Echo curve: 5 instances at -0.5 magnitude, 1.70 compounding.
	# factor_sum = 0.5 * (1 + 1.70 + 1.70^2 + 1.70^3 + 1.70^4) = 9.42755, matching the kit's
	# own 9.43x projection. Fixed defence cancels between skill_aggregate and baseline_damage
	# (Skills.MitigatedDamageUnrounded is linear in the aggregate), so the ratio reduces to
	# own_bucket_factor * factor_sum exactly.
	var skill_entry: Dictionary = {"class": KitContributionManifest.Contribution_Class.Channel1, "magnitude": 0.0}
	var bonus: Dictionary = {"magnitude": -0.5, "instances": 5, "instance_compounding": 1.70}
	var baseline_damage: float = Skills.MitigatedDamageUnrounded(100.0, 100.0, 1.0, 1.0)
	var ratio: float = BurstReachability._MultiInstanceContrastRatio(
			skill_entry, bonus, 100.0, 100.0, baseline_damage, 1.0)
	assert_almost_eq(ratio, 9.42755, 0.0001,
		"A compounding gated_bonus must sum (1+magnitude)*compounding^i across its declared instances")

func test_multi_instance_contrast_ratio_is_flat_when_compounding_is_omitted() -> void:
	# A generic flat curve: 8 instances at -0.1 magnitude, no instance_compounding
	# declared (defaults to 1.0, flat) -> 8 * 0.9 = 7.2.
	var skill_entry: Dictionary = {"class": KitContributionManifest.Contribution_Class.Channel1, "magnitude": 0.0}
	var bonus: Dictionary = {"magnitude": -0.1, "instances": 8}
	var baseline_damage: float = Skills.MitigatedDamageUnrounded(100.0, 100.0, 1.0, 1.0)
	var ratio: float = BurstReachability._MultiInstanceContrastRatio(
			skill_entry, bonus, 100.0, 100.0, baseline_damage, 1.0)
	assert_almost_eq(ratio, 7.2, 0.0001,
		"An omitted instance_compounding must default to a flat 1.0x curve across instances")

func test_cut_the_cloth_manifest_entry_reproduces_its_projected_legendary_curve() -> void:
	# Role_Kit_Design.md 9.2's own worked figure: 9 instances (base cast + 7 Tension + Black
	# Thread's extra instance) at 0.9 base strength * 1.19 (Legendary self-bonus) - 1 = +0.071
	# magnitude, flat (no instance_compounding) -> 9 * 1.071 = 9.639, reproducing the doc's
	# ~53.0x contrast ratio against an illustrative 5.5 team product (9.639 * 5.5 ~= 53.0).
	var herald_entry: Dictionary = KitContributionManifest.MANIFEST[Types.Role.Herald_Of_The_Loom]
	var cut_the_cloth: Dictionary = {}
	for skill: Dictionary in herald_entry["skills"]:
		if("Cut the Cloth" == skill["name"]):
			cut_the_cloth = skill
	assert_true(cut_the_cloth.has("gated_bonus"), "Cut the Cloth must declare a gated_bonus")
	var bonus: Dictionary = cut_the_cloth["gated_bonus"]
	assert_eq(bonus["instances"], 9)
	assert_almost_eq(bonus["magnitude"], 0.071, 0.0001)
	assert_eq(bonus["fold"], "separate_instance")

	var baseline_damage: float = Skills.MitigatedDamageUnrounded(100.0, 100.0, 1.0, 1.0)
	var ratio: float = BurstReachability._MultiInstanceContrastRatio(
			cut_the_cloth, bonus, 100.0, 100.0, baseline_damage, 1.0)
	assert_almost_eq(ratio, 9.639, 0.0001,
		"Cut the Cloth's manifest entry should reproduce Role_Kit_Design.md 9.2's 9*1.071 curve")

func test_multi_instance_contrast_ratio_clamps_instances_to_the_cascade_cap() -> void:
	var skill_entry: Dictionary = {"class": KitContributionManifest.Contribution_Class.Channel1, "magnitude": 0.0}
	var uncapped: Dictionary = {"magnitude": 0.0, "instances": CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION}
	var overshot: Dictionary = {"magnitude": 0.0, "instances": CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION + 50}
	var baseline_damage: float = Skills.MitigatedDamageUnrounded(100.0, 100.0, 1.0, 1.0)
	var uncapped_ratio: float = BurstReachability._MultiInstanceContrastRatio(
			skill_entry, uncapped, 100.0, 100.0, baseline_damage, 1.0)
	var overshot_ratio: float = BurstReachability._MultiInstanceContrastRatio(
			skill_entry, overshot, 100.0, 100.0, baseline_damage, 1.0)
	assert_almost_eq(overshot_ratio, uncapped_ratio, 0.0001,
		"A declared instance count past the per-action cascade cap must be clamped to it")

func test_gated_contrast_ratio_routes_separate_instance_and_sustained_ticks_to_their_own_field() -> void:
	var skill_entry: Dictionary = {"class": KitContributionManifest.Contribution_Class.Channel1, "magnitude": 0.0}
	var baseline_damage: float = Skills.MitigatedDamageUnrounded(100.0, 100.0, 1.0, 1.0)
	var separate_entry: Dictionary = skill_entry.duplicate()
	separate_entry["gated_bonus"] = {"magnitude": 0.0, "fold": "separate_instance", "instances": 1}
	var separate_ratios: Array[float] = BurstReachability._GatedContrastRatios(
			separate_entry, 100.0, 100.0, baseline_damage, 1.0)
	assert_gt(separate_ratios[0], 0.0, "A separate_instance fold must land in the repeat slot")
	assert_almost_eq(separate_ratios[1], 0.0, 0.0001, "A separate_instance fold must not land in the sustained slot")

	var sustained_entry: Dictionary = skill_entry.duplicate()
	sustained_entry["gated_bonus"] = {"magnitude": 0.0, "fold": "sustained_ticks", "instances": 1}
	var sustained_ratios: Array[float] = BurstReachability._GatedContrastRatios(
			sustained_entry, 100.0, 100.0, baseline_damage, 1.0)
	assert_almost_eq(sustained_ratios[0], 0.0, 0.0001, "A sustained_ticks fold must not land in the repeat slot")
	assert_gt(sustained_ratios[1], 0.0, "A sustained_ticks fold must land in the sustained slot")

# --- Generalized gate surfacing (CandidateResult.assumed_gates / reagent_assumed) ---

func test_a_non_reagent_gate_is_surfaced_without_setting_reagent_assumed() -> void:
	var presets: Array[CharacterPreset] = [EMISSARY, THIEF, WARLORD]
	var modified_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var warlord_entry: Dictionary = modified_manifest[Types.Role.Warlord]
	warlord_entry["skills"][0]["gated_bonus"] = {"bucket_key": "", "magnitude": 0.0,
			"class": KitContributionManifest.Contribution_Class.Channel1, "fold": "sustained_ticks",
			"gate": &"debuff_count", "instances": 2}

	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(presets, 0, modified_manifest)
	var pinned: BurstReachability.CandidateResult = result.Pinned(2, "Shield Slam")
	assert_not_null(pinned, "Warlord's Shield Slam must still be a scored candidate")
	assert_true(pinned.assumed_gates.has(&"debuff_count"),
		"A declared gate must be surfaced on assumed_gates regardless of which mechanic it names")
	assert_false(pinned.reagent_assumed,
		"A non-reagent gate must not set reagent_assumed")
	assert_gt(pinned.sustained_contrast_ratio, 0.0,
		"A sustained_ticks gated_bonus must contribute a nonzero sustained_contrast_ratio")
	assert_almost_eq(pinned.total_contrast_ratio, pinned.contrast_ratio, 0.0001,
		"sustained_contrast_ratio must never be folded into total_contrast_ratio")

# --- Zone-trigger damage enumeration (_ZoneTriggerEnemyDamageEffects) ---

func test_zone_only_skill_is_enumerated_from_its_enemy_facing_on_trigger_damage() -> void:
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_sorcerer_scholar_tactician())
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Unstable Rift")
	assert_not_null(pinned,
		"Unstable Rift must be enumerated as a candidate from its zone-trigger damage alone")
	# Both the enemy (0.3 Mysticism) and ally (0.15 Mysticism) on_trigger DamageEffects scale
	# the same attribute on the same caster, so the ally-facing half's exclusion is visible
	# directly in base_term: 0.3, not the combined 0.45, against the Sorcerer's own Mysticism
	# 1.0 basic skill (Arc Lash).
	assert_almost_eq(pinned.base_term, 0.3, 0.0001,
		"Only the enemy-facing on_trigger DamageEffect must be counted, not the ally-facing one")
	assert_true(pinned.assumed_gates.has(&"zone_charges_consumed"),
		"Unstable Rift's remaining zone charges must surface their own gate")
	assert_gt(pinned.sustained_contrast_ratio, 0.0,
		"Unstable Rift's remaining zone charges must contribute a nonzero sustained_contrast_ratio")

# --- Defence-ignore / Defence-reduction (Role_Kit_Design.md section 11's closed gap) ---

func test_defence_ignore_points_reads_passive_rate_times_skill_multiple() -> void:
	var role_entry: Dictionary = {"passive": [{"defence_ignore": {"rate": 0.20}}]}
	var skill_entry: Dictionary = {"defence_ignore": {"multiple": 2.5}}
	var points: float = BurstReachability._DefenceIgnorePoints(role_entry, skill_entry, 120.0)
	assert_almost_eq(points, 60.0, 0.0001, "0.20 rate * 2.5 multiple * 120 Defence = 60 points")

func test_defence_ignore_points_is_zero_without_a_passive_rate() -> void:
	var role_entry: Dictionary = {"passive": [{}]}
	var skill_entry: Dictionary = {"defence_ignore": {"multiple": 2.5}}
	assert_eq(BurstReachability._DefenceIgnorePoints(role_entry, skill_entry, 120.0), 0.0,
		"A caster with no declared passive rate must ignore nothing, regardless of the skill's multiple")

func test_defence_ignore_points_is_zero_without_a_skill_multiple() -> void:
	var role_entry: Dictionary = {"passive": [{"defence_ignore": {"rate": 0.20}}]}
	assert_eq(BurstReachability._DefenceIgnorePoints(role_entry, {}, 120.0), 0.0,
		"A skill entry with no declared multiple must not carry the passive's rate")

func test_defence_reduction_reaches_from_any_teammates_declared_team_reach_shred() -> void:
	var attacker: Character = Character.new()
	attacker._role = Types.Role.Thief
	var shredder: Character = Character.new()
	shredder._role = Types.Role.Architect
	var manifest: Dictionary = {
		Types.Role.Architect: {"skills": [{"defence_reduction":
				{"fraction": 0.44, "reach": "team", "gate": &"defence_reduction_applied"}}]},
	}
	var characters: Array[Character] = [attacker, shredder]

	var result: Dictionary = BurstReachability._ContributeDefenceReduction(characters, manifest)

	assert_almost_eq(result.get("fraction", 0.0), 0.44, 0.0001,
		"The Architect's exported shred must reach a teammate's own candidate")
	assert_true((result.get("gates", []) as Array).has(&"defence_reduction_applied"),
		"The shred's own gate must be surfaced for the caller to append")

func test_defence_reduction_ignores_an_entry_without_team_reach() -> void:
	var character: Character = Character.new()
	character._role = Types.Role.Architect
	var manifest: Dictionary = {
		Types.Role.Architect: {"skills": [{"defence_reduction": {"fraction": 0.44}}]},
	}
	var characters: Array[Character] = [character]

	var result: Dictionary = BurstReachability._ContributeDefenceReduction(characters, manifest)

	assert_eq(result.get("fraction", 0.0), 0.0, "A non-team-reach entry must not contribute a shred")

func test_effective_defence_for_candidate_applies_the_shred_before_the_ignore_points() -> void:
	# Shredded first: 120 * (1 - 0.44) = 67.2; the ignore's own 24 points then come off
	# that — the same two-step order battle_resolver.gd's real mitigation performs.
	var effective: float = BurstReachability._EffectiveDefenceForCandidate(120.0, 0.44, 24.0)
	assert_almost_eq(effective, 43.2, 0.01)

func test_effective_defence_for_candidate_floors_at_zero() -> void:
	var effective: float = BurstReachability._EffectiveDefenceForCandidate(50.0, 0.0, 1000.0)
	assert_eq(effective, 0.0, "Defence must floor at zero, never go negative")

func test_thief_pierce_weakness_gains_contrast_from_the_architects_exported_shred() -> void:
	# Route G (Role_Kit_Design.md section 9.12/9.10): the Thief's own base-referenced ignore
	# and the Architect's exported Defence shred must compound rather than one eating the
	# other's contribution — end-to-end, through the real MANIFEST.
	var without_architect: Array[CharacterPreset] = [THIEF, WARLORD, CHRONOPHAGE]
	var with_architect: Array[CharacterPreset] = [THIEF, WARLORD, ARCHITECT]
	var baseline: BurstReachability.CandidateResult = (
			BurstReachability.ScoreTeam(without_architect).Pinned(0, "Pierce weakness"))
	var shredded: BurstReachability.CandidateResult = (
			BurstReachability.ScoreTeam(with_architect).Pinned(0, "Pierce weakness"))

	assert_not_null(baseline, "Pierce weakness must be a scored candidate without the Architect")
	assert_not_null(shredded, "Pierce weakness must be a scored candidate with the Architect")
	assert_gt(shredded.contrast_ratio, baseline.contrast_ratio,
		"The Architect's exported Defence shred must raise the Thief's own contrast ratio")

# --- Echo modifier (_EchoModifierProduct) ---

func test_own_cascade_echo_keeps_standing_factors_but_not_what_the_cast_spent() -> void:
	var buckets: Dictionary = {&"Opportunist": 0.5, &"Daunting_Strength": 1.0,
			CombinedDamageModifier.TRAIT_RESOURCE_KEY: 0.3}
	assert_almost_eq(BurstReachability._EchoModifierProduct(buckets, false), 1.5, 0.0001,
		"A skill's own Echo must re-read standing factors and lose consumed ones")

func test_replaying_echo_repeats_what_the_cast_spent() -> void:
	var buckets: Dictionary = {&"Opportunist": 0.5, &"Daunting_Strength": 1.0}
	assert_almost_eq(BurstReachability._EchoModifierProduct(buckets, true), 3.0, 0.0001,
		"A replayed cast must repeat consumed factors as well as standing ones")

func test_borrowed_time_echo_scales_with_the_whole_cast_for_team_factors() -> void:
	var presets: Array[CharacterPreset] = [
			load("res://Data/Character_Player_Variants/Thief.tres"),
			load("res://Data/Character_Player_Variants/Tactician.tres"),
			load("res://Data/Character_Player_Variants/Chronophage.tres")]
	var candidate: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(presets).Pinned(0, "Stab")
	assert_almost_eq(candidate.repeat_contrast_ratio, candidate.contrast_ratio * 0.6, 0.0001,
		"Borrowed Time's Echo must carry Daunting Strength at the granter's own strength")

# --- Debuff density and tick payloads ---

func _characters_for(p_paths: Array[String]) -> Array[Character]:
	var characters: Array[Character] = []
	for path in p_paths:
		var character: Character = Character.new()
		character.InstantiateNew(load(path), characters.size())
		characters.append(character)
		autofree(character)
	return characters

func test_team_debuff_types_ignore_self_targeted_debuffs_and_read_zone_triggers() -> void:
	var characters: Array[Character] = _characters_for(
			["res://Data/Character_Player_Variants/Plague_Doctor.tres",
			"res://Data/Character_Player_Variants/Warlord.tres"])
	var types: Array[StringName] = BurstReachability._TeamDebuffTypes(characters, KitContributionManifest.MANIFEST)
	assert_true(types.has(&"Blight"), "A zone's on-trigger debuff must count")
	assert_true(types.has(&"Plague"), "A skill's debuff on an enemy must count")
	assert_true(types.has(&"Enfeeble"), "A passive's applied_debuffs must count")
	assert_false(types.has(&"Slow"), "A debuff the Warlord places on himself must not count")

func test_debuff_tick_ratio_resolves_once_per_debuff_type_without_defence() -> void:
	var bonus: Dictionary = {"magnitude": -0.75, "instances": 3}
	assert_almost_eq(BurstReachability._DebuffTickContrastRatio(bonus, 100.0, 50.0, 1.0, 4), 6.0, 0.0001,
		"3 ticks at 4 resolutions of 25 damage each against a 50 baseline must be 6x")

func test_debuff_tick_growth_rises_with_each_resolution() -> void:
	var bonus: Dictionary = {"magnitude": 0.0, "instances": 2, "tick_growth": {"maximum": 4.0, "half_count": 39.0}}
	assert_almost_eq(BurstReachability._DebuffTickContrastRatio(bonus, 100.0, 100.0, 1.0, 1), 2.1, 0.0001,
		"The first resolution must be flat and the second +10%")

func test_snapshot_product_drops_spent_factors_and_the_skills_own_bucket() -> void:
	var buckets: Dictionary = {&"Outbreak": 0.5, &"Daunting_Strength": 1.0, &"Hemorrhage": 0.3}
	assert_almost_eq(BurstReachability._SnapshotModifierProduct(buckets, {"bucket_key": "Outbreak"}), 1.3, 0.0001,
		"A snapshot must keep only standing factors")

func test_outbreak_reads_the_teams_debuff_density() -> void:
	var presets: Array[CharacterPreset] = [
			load("res://Data/Character_Player_Variants/Plague_Doctor.tres"),
			load("res://Data/Character_Player_Variants/Warlord.tres"),
			load("res://Data/Character_Player_Variants/Symbiote.tres")]
	var candidate: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(presets).Pinned(0, "Outbreak")
	assert_almost_eq(candidate.buckets[&"Outbreak"], 0.24, 0.0001,
		"Plague, Blight and Enfeeble must give Outbreak three types at +8% each")
