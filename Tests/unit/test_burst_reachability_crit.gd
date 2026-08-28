extends GutTest

## Coverage for Scripts/Debug/burst_reachability.gd's critical-strike scoring: the expected-value
## crit factor formula (_CritFactor), its allow_critical blending (_EffectiveCritFactor /
## _CritEligibleAggregate), and the Appraiser Role's manifest-driven crit grants — the gap this
## file closes is that every damaging skill was previously scored with the crit multiplier
## hardcoded to 1.0, so the whole Appraiser Role (No Wasted Margin, Sizing Cut, Flaw Analysis,
## Full Appraisal) scored bit-identically whether present on a team or not.

const APPRAISER = preload("res://Data/Character_Player_Variants/Appraiser.tres")
const EMISSARY = preload("res://Data/Character_Player_Variants/Emissary.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")

func _appraiser_emissary_warlord() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [APPRAISER, EMISSARY, WARLORD]
	return presets

func _character(p_preset: CharacterPreset, p_index: int = 0) -> Character:
	var character: Character = Character.new()
	character.InstantiateNew(p_preset, p_index)
	return character

# --- _CritFactor: the expected-value formula itself ---

func test_crit_factor_matches_base_attributes_with_no_grants() -> void:
	# Warlord carries no preset override, so CritChance/CritDamage are GameBalance's base
	# values (5, 150). 10.0 here is an arbitrary test value, unrelated to the reference
	# profile's own Knowledge (BlowoutCalibration.REFERENCE_PROFILES[0][3]).
	var crit: Dictionary = BurstReachability._CritFactor(_character(WARLORD), {}, {}, 10.0)
	assert_almost_eq(crit.get("chance"), 5.0, 0.0001, "Chance must equal the base CritChance attribute")
	assert_almost_eq(crit.get("damage_multiplier"), 1.45, 0.0001,
		"Multiplier must be (150 - 10*0.5) * 0.01 = 1.45")
	assert_almost_eq(crit.get("factor"), 1.0225, 0.0001,
		"Expected factor must be 1 + (chance/100) * (multiplier - 1) = 1 + 0.05*0.45")

func test_crit_factor_floors_the_multiplier_at_minimum_crit_damage() -> void:
	# A boss Knowledge high enough to drive (CritDamage - Knowledge*0.5) below the floor.
	var crit: Dictionary = BurstReachability._CritFactor(_character(WARLORD), {}, {}, 1000.0)
	assert_almost_eq(crit.get("damage_multiplier"), GameBalance.MINIMUM_CRIT_DAMAGE * 0.01, 0.0001,
		"The multiplier must never fall below GameBalance.MINIMUM_CRIT_DAMAGE, matching the runtime's own floor")

func test_crit_factor_leaves_chance_unclamped_for_overflow_conversion() -> void:
	var points: Dictionary = {Types.Attribute.CritChance: 500.0}
	var crit: Dictionary = BurstReachability._CritFactor(_character(WARLORD), {}, points, 10.0)
	assert_almost_eq(crit.get("chance"), 505.0, 0.0001,
		"Chance must stay unclamped so the excess above 100 is visible to No Wasted Margin's conversion")

func test_crit_factor_converts_chance_overflow_into_crit_damage() -> void:
	var points: Dictionary = {Types.Attribute.CritChance: 200.0}
	var crit: Dictionary = BurstReachability._CritFactor(_character(WARLORD), {}, points, 10.0, 3.0)
	# chance = 5 + 200 = 205; overflow = (205 - 100) * 3.0 = 315 crit-damage points;
	# damage_multiplier = (150 + 315 - 10*0.5) * 0.01 = 4.6; probability saturates at 1.0.
	assert_almost_eq(crit.get("damage_multiplier"), 4.6, 0.0001,
		"Critical Chance above 100 must convert into Critical Damage at the given overflow rate")
	assert_almost_eq(crit.get("factor"), 4.6, 0.0001,
		"With probability saturated at 1.0, factor equals the damage_multiplier directly")

func test_crit_factor_reads_a_higher_base_crit_chance_off_the_preset() -> void:
	# The Appraiser's own preset sets _critical_chance = 30, unlike Warlord's base-5 default.
	var crit: Dictionary = BurstReachability._CritFactor(_character(APPRAISER), {}, {}, 10.0)
	assert_almost_eq(crit.get("chance"), 30.0, 0.0001,
		"A preset's own elevated CritChance must be read as the base value, not GameBalance's default")

# --- _EffectiveCritFactor / _CritEligibleAggregate: the allow_critical blend ---

func _damage_skill(p_allow_critical: bool) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Test Strike"
	skill.target = Types.Skill_Target.Single_Enemy
	skill.cooldown = 2
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	effect.allow_critical = p_allow_critical
	skill.effects = [effect]
	return skill

func test_crit_eligible_aggregate_is_zero_when_allow_critical_is_false() -> void:
	var character: Character = _character(WARLORD)
	var eligible: float = BurstReachability._CritEligibleAggregate(_damage_skill(false), character)
	assert_almost_eq(eligible, 0.0, 0.0001,
		"A DamageEffect with allow_critical = false must contribute nothing to the crit-eligible aggregate")

func test_crit_eligible_aggregate_equals_full_aggregate_when_allow_critical_is_true() -> void:
	var character: Character = _character(WARLORD)
	var skill: Skill = _damage_skill(true)
	var eligible: float = BurstReachability._CritEligibleAggregate(skill, character)
	var total: float = BurstReachability._ScaledAggregate(skill, character)
	assert_almost_eq(eligible, total, 0.0001,
		"A fully crit-eligible skill's eligible aggregate must equal its total aggregate")

func test_effective_crit_factor_is_neutral_when_the_skill_cannot_crit() -> void:
	var character: Character = _character(WARLORD)
	var skill: Skill = _damage_skill(false)
	var total: float = BurstReachability._ScaledAggregate(skill, character)
	var effective: float = BurstReachability._EffectiveCritFactor(skill, character, {}, total, 2.0)
	assert_almost_eq(effective, 1.0, 0.0001,
		"allow_critical = false must yield an effective crit factor of 1.0 regardless of the caster's own crit_factor")

func test_effective_crit_factor_equals_the_full_crit_factor_when_fully_eligible() -> void:
	var character: Character = _character(WARLORD)
	var skill: Skill = _damage_skill(true)
	var total: float = BurstReachability._ScaledAggregate(skill, character)
	var effective: float = BurstReachability._EffectiveCritFactor(skill, character, {}, total, 2.0)
	assert_almost_eq(effective, 2.0, 0.0001,
		"A fully crit-eligible skill's effective factor must equal the caster's own crit_factor untouched")

func test_allow_critical_false_scores_a_strictly_lower_contrast_ratio() -> void:
	# Same caster, same damage_scaling, same product (no reachable bucket): the only difference
	# is allow_critical. A caster with a real crit chance/damage must score the crit-eligible
	# skill strictly higher via Skills.MitigatedDamageUnrounded's own crit_multiplier argument.
	var character: Character = _character(APPRAISER)
	var defence: float = BlowoutCalibration.REFERENCE_PROFILES[0][2]
	var boss_knowledge: float = BlowoutCalibration.REFERENCE_PROFILES[0][3]
	var crit: Dictionary = BurstReachability._CritFactor(character, {}, {}, boss_knowledge)
	assert_gt(crit.get("factor"), 1.0, "Sanity: the Appraiser's own base 30% crit chance must produce a >1.0 factor")

	var eligible_skill: Skill = _damage_skill(true)
	var aggregate: float = BurstReachability._ScaledAggregate(eligible_skill, character)
	var eligible_damage: float = Skills.MitigatedDamageUnrounded(defence, aggregate, crit.get("factor"), 1.0)
	var ineligible_damage: float = Skills.MitigatedDamageUnrounded(defence, aggregate, 1.0, 1.0)
	assert_gt(eligible_damage, ineligible_damage,
		"A crit-eligible skill must resolve to more damage than an identical allow_critical = false skill")

# --- Manifest-driven Appraiser grants, through the real ScoreTeam path ---

## The real manifest with every Appraiser granted_attribute_buff (Sizing Cut, Flaw Analysis,
## Full Appraisal) and the passive's crit_overflow_rate stripped back to empty — isolates their
## crit contribution from everything else the Appraiser Role does.
func _manifest_without_appraiser_crit_grants() -> Dictionary:
	var modified: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var appraiser_entry: Dictionary = modified[Types.Role.Appraiser]
	appraiser_entry["passive"][0].erase("crit_overflow_rate")
	appraiser_entry["skills"][0].erase("granted_attribute_buff")
	appraiser_entry["skills"][1].erase("granted_attribute_buff")
	appraiser_entry["skills"][2].erase("granted_attribute_buff")
	return modified

func test_appraiser_present_raises_crit_chance_on_a_teammates_own_candidate() -> void:
	# Sizing Cut's Exposed Facet has "team" reach: it must raise the Warlord's own crit_chance
	# even though the Warlord never cast it, precisely because it debuffs the shared enemy
	# rather than buffing an ally.
	var with_appraiser: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_appraiser_emissary_warlord())
	var without_appraiser_crit: BurstReachability.TeamResult = BurstReachability.ScoreTeam(
			_appraiser_emissary_warlord(), 0, _manifest_without_appraiser_crit_grants())

	# _appraiser_emissary_warlord()'s own order puts the Warlord at index 2.
	var with_pinned: BurstReachability.CandidateResult = with_appraiser.Pinned(2, "Shield Slam")
	var without_pinned: BurstReachability.CandidateResult = without_appraiser_crit.Pinned(2, "Shield Slam")
	assert_not_null(with_pinned, "Warlord's Shield Slam must be a scored candidate")
	assert_not_null(without_pinned, "Warlord's Shield Slam must still be scored against the stripped manifest")
	assert_gt(with_pinned.crit_chance, without_pinned.crit_chance,
		"The real manifest's Flaw Analysis grant must raise a teammate's reachable crit_chance " +
		"above the stripped manifest's, since bucket_key/magnitude alone never carried this before")

func test_crit_chance_change_cancels_out_of_contrast_ratio_for_a_symmetric_skill() -> void:
	# Deliberate consequence, not a bug: crit_chance/crit_damage are caster-scoped, so the SAME
	# factor mitigates both the burst skill and its basic-skill baseline whenever every
	# DamageEffect involved allows crit (true for every current .tres) — it cancels out of the
	# ratio contrast_ratio measures. This guards that cancellation rather than being surprised
	# by it: a real crit-chance difference (proven by the sibling test above) must still leave
	# combined_contrast_ratio untouched here.
	var with_appraiser: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_appraiser_emissary_warlord())
	var without_appraiser_crit: BurstReachability.TeamResult = BurstReachability.ScoreTeam(
			_appraiser_emissary_warlord(), 0, _manifest_without_appraiser_crit_grants())

	var warlord_index: int = with_appraiser.candidates[0].caster_index
	for candidate in with_appraiser.candidates:
		if(Types.Role.Warlord == candidate.caster_role):
			warlord_index = candidate.caster_index
			break
	var with_pinned: BurstReachability.CandidateResult = with_appraiser.Pinned(warlord_index, "Shield Slam")
	var without_pinned: BurstReachability.CandidateResult = without_appraiser_crit.Pinned(warlord_index, "Shield Slam")
	assert_almost_eq(with_pinned.contrast_ratio, without_pinned.contrast_ratio, 0.0001,
		"contrast_ratio must be unaffected by a caster-level crit_chance change when every " +
		"DamageEffect involved allows crit, since the same factor mitigates numerator and denominator")
	assert_almost_eq(with_pinned.combined_contrast_ratio, without_pinned.combined_contrast_ratio, 0.0001,
		"combined_contrast_ratio must be unaffected for the same reason")

func test_full_appraisal_grant_scales_with_the_appraisers_own_crit_attributes() -> void:
	# Keen Edge/Lethal Precision are "source_attribute" grants: they must scale with whichever
	# Critical Chance/Critical Damage the granting Appraiser actually has, not a fixed number.
	var appraiser: Character = _character(APPRAISER)
	appraiser._attributes[Types.Attribute.CritChance] = 60
	appraiser._attributes[Types.Attribute.CritDamage] = 250
	var characters: Array[Character] = [appraiser, _character(WARLORD, 1)]
	var bonus: Dictionary = BurstReachability._ContributeGrantedAttributeBuffs(
			characters, 1, KitContributionManifest.MANIFEST)
	var points: Dictionary = bonus.get("points", {})
	# 15 (Sizing Cut's flat Exposed Facet) + 60 (Full Appraisal's Keen Edge, the Appraiser's own
	# Critical Chance).
	assert_almost_eq(points.get(Types.Attribute.CritChance, 0.0), 75.0, 0.0001,
		"The Warlord's Critical Chance points must include the Appraiser's own 60 via Keen Edge")
	# 0.6 * 45 Knowledge (Flaw Analysis's Cracked Facet) + 250 (Full Appraisal's Lethal
	# Precision, the Appraiser's own Critical Damage).
	assert_almost_eq(points.get(Types.Attribute.CritDamage, 0.0), 277.0, 0.0001,
		"The Warlord's Critical Damage points must include the Appraiser's own 250 via Lethal Precision")

# --- Regression guard: a non-Appraiser team's pinned product/ratio must be untouched ---

func test_non_appraiser_pinned_product_is_unaffected_by_crit_scoring() -> void:
	var sorcerer_scholar_tactician: Array[CharacterPreset] = [
		preload("res://Data/Character_Player_Variants/Sorcerer.tres"),
		preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres"),
		preload("res://Data/Character_Player_Variants/Tactician.tres"),
	]
	var result: BurstReachability.TeamResult = BurstReachability.ScoreTeam(sorcerer_scholar_tactician)
	var pinned: BurstReachability.CandidateResult = result.Pinned(0, "Cataclysm")
	assert_not_null(pinned, "Sorcerer's Cataclysm must be a scored candidate")
	assert_almost_eq(pinned.product, 2.8, 0.01,
		"Regression pin, unchanged by crit scoring: composed product for this team bursting Cataclysm")
